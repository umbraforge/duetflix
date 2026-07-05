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
    var newMatch: DeckMovie?                 // yeni çıkan eşleşme → kutlama tetikler

    private let db = Firestore.firestore()
    private let tmdb: TMDBService = TMDBServiceLive()
    private let roomService = RoomService()
    private var listener: ListenerRegistration?
    private var uid = ""
    private var deckPage = 1
    private var didInitIndex = false         // konumu Firestore'dan sadece bir kez oku
    private var isRefilling = false
    private var seenMatchIDs: Set<Int> = []  // daha önce kutladığımız eşleşmeler
    private var didSeedMatches = false        // ilk snapshot'ta eski eşleşmeleri "görülmüş" say

    // Deste bitti mi (bu oyuncu için)
    var isFinished: Bool { currentIndex >= deck.count }
    // Şu anki kart
    var currentMovie: DeckMovie? { currentIndex < deck.count ? deck[currentIndex] : nil }

    func listen(code: String, uid: String) {
        self.uid = uid
        listener?.remove()
        listener = db.collection("rooms").document(code)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let room = try? snapshot?.data(as: Room.self) else { return }
                self.deck = room.deck ?? []
                self.deckPage = room.deckPage ?? 1
                self.likeCount = room.likes?[uid]?.count ?? 0
                // Konumu yalnızca ilk snapshot'ta oku (devam edince kaldığı yerden başlasın)
                if !self.didInitIndex {
                    self.currentIndex = room.progress?[uid] ?? 0
                    self.didInitIndex = true
                }
                self.updateMatches(likes: room.likes)  // ortak beğenileri hesapla
                self.prefetchUpcoming()   // sıradaki posterleri önden indir
            }
    }

    // Eşleşme = odadaki HERKESİN ortak beğendiği film. Firestore her snapshotta
    // tüm likes haritasını verdiği için burada Set kesişimiyle O(toplam beğeni)
    // hesaplıyoruz sonra yalnızca DAHA ÖNCE görmediğimiz eşleşmeyi kutlatıyoruz.
    private func updateMatches(likes: [String: [Int]]?) {
        // Beğeni yapmış oyuncuların listeleri (Duo'da bu iki kişidir)
        let voterLikes = (likes ?? [:]).values.map { $0 }
        guard voterLikes.count >= 2 else { matchedIDs = []; return }

        // İlk listeyi Sete al, kalanlarla kesiştir
        var intersection = Set(voterLikes[0])
        for list in voterLikes.dropFirst() {
            intersection.formIntersection(list)
            if intersection.isEmpty { break }
        }
        matchedIDs = intersection

        // İlk snapshot eski eşleşmeler için kutlama patlamasın (rejoin senaryosu)
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
