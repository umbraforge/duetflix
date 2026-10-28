//
//  LobbyViewModel.swift
//  DuetFlix
//
//  Created by Batu on 4.07.2026.
//

import Foundation
import FirebaseFirestore

@MainActor
@Observable // odaya biri katılınca çıkınca vb olayların direkt viewda gözükmesi için takip ettiriyoruz classı
final class LobbyViewModel {
    private(set) var room: Room?
    private(set) var errorMessage: String?
    private(set) var roomClosed = false
    private(set) var closedBy: String?       // odayı kapatan host'un adı
    private(set) var eventMessage: String?   // X katıldı / X çıktı

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration? // dinleyiciyi kayıt ettiriyoruzki sonradan kapatalım, kapatmazsak bellek sızıntısı !!!!
    private var previousMembers: [String: String] = [:]    // önceki üyeler (kim katıldı/çıktı diffi için)
    private var myUID = ""                                 // kendi olayımı bildirim yapma diye

    private let tmdb: TMDBService = TMDBServiceLive()   // film çekmek için
    private let roomService = RoomService()             // desteyi yazmak için
    private(set) var isStarting = false                 // çift tık koruması
    var deckFilter = MovieFilter()                      // host'un seçtiği deste filtresi
    var needsReward = false                             // filtre hakkı bitti → view ödül ekranı açsın
    var noFilterResults = false                         // filtreye uyan film yok → view mesaj göstersin


    // Odayı gerçek zamanlı dinleme
    func listen(code: String, uid: String) {
        myUID = uid
        listener?.remove() // önceki listener varsa kapat
        listener = db.collection("rooms").document(code)
            .addSnapshotListener {[weak self] snapshot, error in // her değişiklikte ve o anki veriyle hemen dinlemeye başlar, weak self, listener sürekli açık böylece closure güçlü olur ve kapatılamaz retain cycle
                guard let self else {return}
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                if let snapshot, !snapshot.exists { // döküman hala var mı ?
                    // Oda silindi → silinen dökümandan isim okunamaz o yüzden son bilinen room'dan host adını alıyoruz
                    if let host = self.room?.hostID {
                        self.closedBy = self.room?.members[host]
                    }
                    self.roomClosed = true
                    return
                }
                guard let newRoom = try? snapshot?.data(as: Room.self) else { return } // firestore dökümanını rooma çöz
                self.detectChanges(newRoom.members)   // kim katıldı/çıktı?
                self.room = newRoom
            }
    }

    // Önceki üyelerle karşılaştır → katılan/çıkanı yakala
    private func detectChanges(_ newMembers: [String: String]) {
        if !previousMembers.isEmpty {   // ilk snapshot değilse
            let joined = Set(newMembers.keys).subtracting(previousMembers.keys)   // yeni gelenler
            let left = Set(previousMembers.keys).subtracting(newMembers.keys)     // gidenler
            for id in joined where id != myUID {
                eventMessage = Lf("lobby.joined", newMembers[id] ?? L("lobby.a_player"))
            }
            for id in left where id != myUID {
                // giden artık newMembers'ta yok, ismini previous'tan alıyoruz
                eventMessage = Lf("lobby.left", previousMembers[id] ?? L("lobby.a_player"))
            }
        }
        previousMembers = newMembers
    }
    
    // Ekrandan çıkınca dinlemeyi durdur
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    // Odadan çık. Fire-and-forget: sunucu onayı beklenmez → kullanıcı ekrandan anında
    // çıkar, silme/güncelleme arka planda sync olur (uygulama kapansa bile kuyrukta kalır).
    func leave(code: String, uid: String) {
        let isHost = room?.hostID == uid  // host muyum?
        let isLast = (room?.members.count ?? 0) <= 1 // lobbydeki son kişi miyim?
        if isHost || isLast {
            roomService.deleteRoom(code: code) // oda + deste dokümanı
        } else {
            db.collection("rooms").document(code).updateData([ // sadece beni çıkar
                "members.\(uid)": FieldValue.delete()
            ])
        }
    }

    // Oyundan lobiye dön (odadan çıkma!): "playing"ten uid'i çıkar
    func exitToLobby(code: String, uid: String) async {
        do {
            try await db.collection("rooms").document(code).updateData([
                "playing": FieldValue.arrayRemove([uid])
            ])
        } catch {
            // Geçici hata dinleyici bir sonraki snapshotta durumu düzeltir
        }
    }

    // Lobiden oyuna geri dön playinge uidi ekle
    func rejoin(code: String, uid: String) async {
        do {
            try await db.collection("rooms").document(code).updateData([
                "playing": FieldValue.arrayUnion([uid])
            ])
        } catch {
            // Geçici hata dinleyici bir sonraki snapshotta durumu düzeltir
        }
    }

    // Host oyunu başlatır: desteyi kurar (filtre varsa filtreli, yoksa karışık) ve Firestore'a yazar.
    // Filtreli deste bir filtre hakkı yakar; hak yoksa host ödüllü reklamla kazanır.
    // Karışık deste (filtresiz) her zaman bedava.
    func startGame(code: String, credits: FilterCredits) async {
        guard !isStarting else { return }

        let wantsFilter = !deckFilter.isDefault
        // Filtre istiyor ama hakkı yoksa → ödül ekranı (oyun başlamaz)
        if wantsFilter && credits.isEmpty {
            needsReward = true
            return
        }

        isStarting = true
        defer { isStarting = false }

        // Filtreli deste boş dönerse KARIŞIĞA DÜŞME → host'a "kriterlere uyan film yok" de.
        let movies: [Movie]
        if wantsFilter {
            movies = await filteredDeck()
            guard !movies.isEmpty else { noFilterResults = true; return }
        } else {
            movies = await mixedDeck()
            guard !movies.isEmpty else { errorMessage = "Deste oluşturulamadı"; return }
        }

        do {
            let players = Array((room?.members ?? [:]).keys)   // başlarken herkes oyunda
            // Filtreli deste ise parametreleri odaya yaz → refill aynı filtreyle devam etsin
            let filterParams = wantsFilter ? deckFilter.discoverParams : nil
            try await roomService.startGame(code: code, movies: movies, page: 1,
                                            players: players, filterParams: filterParams)
            // App Review demo modu: simüle partner varsa tüm filmleri "beğenmiş" say
            if room?.members[DemoMode.botUID] != nil {
                try await roomService.seedDemoLikes(code: code, movieIDs: movies.map(\.id))
            }
            // Filtreli deste kuruldu → bir hak harca
            if wantsFilter { credits.spend() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Filtreli deste: seçili filtreden ilk sayfa (20 film), sıralaması korunur.
    // Deste bitmeye yakın refill AYNI filtreyle sayfa 2, 3… diye devam eder (odaya kayıtlı).
    private func filteredDeck() async -> [Movie] {
        (try? await tmdb.fetchDiscover(filter: deckFilter, page: 1)) ?? []
    }

    // Bedava: karışık deste — popüler (rastgele sayfa) + yüksek puanlı + rastgele bir tür,
    // tekrarsız, karıştırılmış. "Hep aynı 20 popüler" hissini kırar.
    private func mixedDeck() async -> [Movie] {
        let page = Int.random(in: 1...3)
        let genreID = [28, 35, 27, 878, 18, 53, 10749, 16].randomElement()!
        async let a = tmdb.fetchPopular(page: page)
        async let b = tmdb.fetchDiscover(filter: MovieFilter(sort: .topRated), page: 1)
        async let c = tmdb.fetchDiscover(filter: MovieFilter(genres: [genreID]), page: 1)
        let all = ((try? await a) ?? []) + ((try? await b) ?? []) + ((try? await c) ?? [])
        var seen = Set<Int>()
        return all.filter { seen.insert($0.id).inserted }.shuffled()
    }
}
