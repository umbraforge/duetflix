//
//  SwipeViewModel.swift
//  DuetFlix
//
//  Swipe destesini gerçek zamanlı dinler, oyuncunun konumunu yönetir,
//  swipe'ları Firestore'a kaydeder, deste bitmeye yakın yeni sayfa çeker.
//

import Foundation
import FirebaseFirestore
import Kingfisher

@MainActor
@Observable
final class SwipeViewModel {
    private(set) var deck: [DeckMovie] = []
    private(set) var currentIndex = 0        // kaçıncı karttayız (yerel, anlık)
    private(set) var likeCount = 0           // bu oyuncunun beğeni sayısı
    private(set) var refillError = false     // yeni filmler yüklenemedi mi
    private(set) var matchedIDs: Set<Int> = []  // herkesin ortak beğendiği film id'leri
    private(set) var rejectedIDs: Set<Int> = [] // listeden çıkarılan film id'leri
    private(set) var memberNames: [String] = [] // odadaki isimler (geçmiş kaydı için)
    var newMatch: DeckMovie?                 // yeni çıkan eşleşme → kutlama tetikler

    private let db = Firestore.firestore()
    private let tmdb: TMDBService = TMDBServiceLive()
    private let roomService = RoomService()
    private var listener: ListenerRegistration?       // ana oda dokümanı (küçük, sık değişir)
    private var deckListener: ListenerRegistration?   // deste alt-dokümanı (büyük, nadir değişir)
    private var uid = ""
    private var roomCode = ""
    private var deckPage = 1
    private var didInitIndex = false         // konumu Firestore'dan sadece bir kez oku
    private var isRefilling = false
    private var seenMatchIDs: Set<Int> = []  // daha önce kutladığımız eşleşmeler
    private var didSeedMatches = false        // ilk snapshot'ta eski eşleşmeleri "görülmüş" say

    // Deste bitti mi (bu oyuncu için)
    var isFinished: Bool { currentIndex >= deck.count }
    // Şu anki kart
    var currentMovie: DeckMovie? { currentIndex < deck.count ? deck[currentIndex] : nil }
    // Eşleşen filmler (deste sırasında, çıkarılanlar hariç) — "Bu gece için" ekranı için
    var matchedMovies: [DeckMovie] {
        deck.filter { matchedIDs.contains($0.id) && !rejectedIDs.contains($0.id) }
    }

    func listen(code: String, uid: String) {
        self.uid = uid
        self.roomCode = code
        let roomRef = db.collection("rooms").document(code)

        // 1) Ana doküman: ilerleme/beğeni/eşleşme — her swipe'ta gelir (deste YOK, hafif)
        listener?.remove()
        listener = roomRef.addSnapshotListener { [weak self] snapshot, _ in
            guard let self, let room = try? snapshot?.data(as: Room.self) else { return }
            self.deckPage = room.deckPage ?? 1
            self.likeCount = room.likes?[uid]?.count ?? 0
            self.memberNames = room.members.values.sorted()   // geçmiş kaydı için
            // Konumu yalnızca ilk snapshot'ta oku (devam edince kaldığı yerden başlasın)
            if !self.didInitIndex {
                self.currentIndex = room.progress?[uid] ?? 0
                self.didInitIndex = true
            }
            self.rejectedIDs = Set(room.rejected ?? [])  // listeden çıkarılanlar
            self.updateMatches(likes: room.likes)         // ortak beğenileri hesapla
        }

        // 2) Deste: üst seviye decks/{code} — büyük ama sadece başlangıç + refill'de değişir
        deckListener?.remove()
        deckListener = db.collection("decks").document(code)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let doc = try? snapshot?.data(as: DeckDoc.self) else { return }
                self.deck = doc.movies ?? []
                self.prefetchUpcoming()   // sıradaki posterleri önden indir
            }
    }

    // Eşleşme = odadaki HERKESİN ortak beğendiği film. Firestore her snapshotta
    // tüm likes haritasını verdiği için burada Set kesişimiyle O(toplam beğeni)
    // hesaplıyoruz sonra yalnızca DAHA ÖNCE görmediğimiz eşleşmeyi kutlatıyoruz.
    private func updateMatches(likes: [String: [Int]]?) {
        // Beğeni yapmış oyuncuların listeleri (Duo'da bu iki kişidir)
        let voterLikes = (likes ?? [:]).values.map { $0 }

        // Kesişim = ortak beğeniler. < 2 oyuncu varsa boş küme.
        var intersection = Set<Int>()
        if let first = voterLikes.first, voterLikes.count >= 2 {
            intersection = Set(first)
            for list in voterLikes.dropFirst() {
                intersection.formIntersection(list)
                if intersection.isEmpty { break }
            }
        }
        matchedIDs = intersection

        // İlk snapshotta mevcut durumu "görülmüş" say (rejoin'de eski eşleşme patlamasın)
        // Oyun başında likes boş → boş tohum → sonraki İLK gerçek
        if !didSeedMatches {
            seenMatchIDs = intersection
            didSeedMatches = true
            return
        }
        // Yeni (ilk kez gördüğümüz) eşleşme varsa kutlamayı tetikle
        let fresh = intersection.subtracting(seenMatchIDs)
        seenMatchIDs.formUnion(intersection)
        if let id = fresh.first, let movie = deck.first(where: { $0.id == id }) {
            newMatch = movie
        }
    }

    // Kutlama kapatıldı
    func clearMatch() { newMatch = nil }

    // Bir eşleşmeyi "bu gece için" listesinden çıkar (iki oyuncuda da gizlenir).
    // Firestorea yazıyoruz; snapshot dönünce rejectedIDs güncellenip liste yenilenir.
    func removeMatch(movieID: Int, code: String) {
        Task { try? await roomService.rejectMatch(code: code, movieID: movieID) }
    }

    // Oyunu bitir → lobiye dön (playing'ten çık). Oda ve eşleşmeler korunur.
    func endGame(code: String) {
        Task { try? await roomService.leaveGame(code: code, uid: uid) }
    }

    // Sıradaki kartların posterlerini arka planda önceden indir
    private func prefetchUpcoming() {
        let start = currentIndex
        let end = min(start + 5, deck.count)
        guard start < end else { return }
        let urls = deck[start..<end].compactMap(\.posterURL)
        ImagePrefetcher(urls: urls).start()
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        deckListener?.remove()
        deckListener = nil
    }

    // Bir kartı kaydır beğen (like=true) / geç (like=false)
    func swipe(like: Bool, code: String) {
        guard currentIndex < deck.count else { return }
        let movie = deck[currentIndex]
        currentIndex += 1
        prefetchUpcoming()
        Task {
            // Firestore'a yaz (kalıcı ilerleme + beğeni)
            try? await roomService.recordSwipe(
                code: code, uid: uid,
                index: currentIndex,
                likedMovieID: like ? movie.id : nil
            )
            await refillIfNeeded(code: code)
        }
    }

    // Deste sonuna yaklaşınca yeni sayfa çek ve ekle
    private func refillIfNeeded(code: String) async {
        guard !isRefilling, currentIndex >= deck.count - 4 else { return }
        isRefilling = true
        defer { isRefilling = false }
        let nextPage = deckPage + 1
        do {
            let movies = try await tmdb.fetchPopular(page: nextPage)
            try await roomService.appendDeck(code: code, movies: movies, page: nextPage)
            refillError = false
        } catch {
            refillError = true
        }
    }

    // Deste yüklenemedi → tekrar dene
    func retryRefill(code: String) async {
        await refillIfNeeded(code: code)
    }
}
