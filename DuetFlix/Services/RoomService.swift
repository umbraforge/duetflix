//
//  RoomService.swift
//  DuetFlix
//
//  Created by Batu on 4.07.2026.
//


//  rooms
//     |_ "oda kodu"
//          |_ hostID: "odayı kuranın uid"
//              |_ status : "lobby"
//                  |_ createdAt: "tarih"
//                      |_ members: ["uid1", "uid2", "uid3", "uid4",] katılımcılar


import Foundation
import FirebaseFirestore // firebase firestore database import

// App Review demo modu: incelemeci Duo eşleşmesini TEK cihazda görebilsin diye.
// Join kutusuna `code` girilince, odaya otomatik bir simüle "partner" eklenir;
// bu partner destedeki tüm filmleri beğenmiş sayılır, böylece incelemeci herhangi
// bir filme sağa kaydırdığında anında eşleşme (kutlama) tetiklenir.
// Not: 2.1(a) — tüm özelliklerin tek cihazda doğrulanabilmesi için.
enum DemoMode {
    static let code = "000000"          // join kutusuna girilecek gizli kod
    static let botUID = "demo-partner"  // simüle partnerin sabit "uid"i
    static let botName = "Demo Partner" // lobide/geçmişte görünecek ad
}

@MainActor
@Observable
final class RoomService {
    private let db = Firestore.firestore()

    // Oda/deste bu süre boyunca yaşar; aktivite (oda kur / başlat / swipe / refill)
    // oldukça tazelenir. Süre dolunca Firestore TTL policy dökümanı otomatik siler
    // → hayalet oda temizliği (force-quit / internet kopması durumları).
    static let ttl: TimeInterval = 12 * 60 * 60   // 12 saat
    private static func expiry() -> Timestamp {
        Timestamp(date: Date().addingTimeInterval(ttl))
    }

    // Oda kurma: kodu LOKAL üret, yazımı sunucu onayını BEKLEMEDEN (fire-and-forget)
    // gönder → kullanıcı anında lobiye geçer. Firestore yazımı lokal cache'e hemen
    // uygulanır + diske kalıcı kuyruğa yazılır (uygulama kapansa bile sonraki açılışta
    // sunucuya gider), listener odayı cache'ten anında görür.
    func createRoom(hostID: String, hostName: String) -> String {
        let code = Self.generateCode()
        db.collection("rooms").document(code).setData([
            "hostID": hostID,
            "status": "lobby",
            "createdAt": FieldValue.serverTimestamp(),
            "members": [hostID: hostName],   // uid → isim
            "expiresAt": Self.expiry()
        ])
        return code
    }

    // App Review demo odası: incelemeci host olur + simüle partner baştan üye eklenir.
    // Böylece "Başlat" butonu (>= 2 üye şartı) hemen aktif olur ve Duo akışı tek
    // cihazda test edilebilir. (create kuralı: host kendini üye ekliyor → geçerli.)
    func createDemoRoom(hostID: String, hostName: String) -> String {
        let code = Self.generateCode()
        db.collection("rooms").document(code).setData([
            "hostID": hostID,
            "status": "lobby",
            "createdAt": FieldValue.serverTimestamp(),
            "members": [hostID: hostName, DemoMode.botUID: DemoMode.botName],
            "expiresAt": Self.expiry()
        ])
        return code
    }

    // Odaya katılma members mapine uid = isim ekleme.
    // Fire-and-forget: fetchRoom (oda var mı + isim çakışması) çağıran tarafta zaten
    // beklendi; bu YAZIMI ayrıca beklemeye gerek yok → kullanıcı anında lobiye geçer.
    func joinRoom(code: String, uid: String, name: String) {
        db.collection("rooms").document(code).updateData([
            "members.\(uid)": name
        ])
    }

    // Odayı bir kez çek (yoksa nil). Hem "oda var mı" hem "isim dolu mu" kontrolü için.
    func fetchRoom(code: String) async throws -> Room? {
        let snapshot = try await db.collection("rooms").document(code).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: Room.self)
    }
    
    // Host oyunu başlatır desteyi AYRI dokümana yaz, sonra ana odayı güncelle
    func startGame(code: String, movies: [Movie], page: Int, players: [String]) async throws {
        let deckData = movies.map(Self.deckEntry)
        let ref = db.collection("rooms").document(code)
        // 1) Büyük desteyi ÜST SEVİYE decks/{code} dokümanına yaz (her swipe'ta
        //    yeniden inmesin). Üst seviye ki TTL onu da otomatik silebilsin.
        try await db.collection("decks").document(code).setData([
            "movies": deckData,
            "expiresAt": Self.expiry()
        ])
        // 2) Ana dokümanın küçük alanları — status/playing en son ki karşı taraf
        //    swipinge geçtiğinde deste dokümanı zaten hazır olsun
        try await ref.updateData([
            "status": "swiping",
            "deckPage": page,
            "playing": players,
            "expiresAt": Self.expiry()
        ])
    }

    // Demo modu: simüle partner destedeki TÜM filmleri beğenmiş say. Böylece
    // incelemeci herhangi bir filme "beğen" derse kesişim dolar → anında eşleşme.
    func seedDemoLikes(code: String, movieIDs: [Int]) async throws {
        try await db.collection("rooms").document(code).updateData([
            "likes.\(DemoMode.botUID)": movieIDs
        ])
    }

    // Oyundan lobiye dön / oyunu bitir playingten uidi çıkar
    func leaveGame(code: String, uid: String) async throws {
        try await db.collection("rooms").document(code).updateData([
            "playing": FieldValue.arrayRemove([uid])
        ])
    }

    // Odayı komple sil: ÖNCE deste (üst seviye decks/{code}), SONRA ana oda.
    // Sıra önemli: deste silme yetkisi ana odada üyelik kontrolü ister; ana oda
    // silinmeden önce deste silinmeli. Fire-and-forget: sunucu onayını beklemeden
    // gönderilir (kuyruğa sırayla girer) → kullanıcı ekrandan anında çıkar.
    func deleteRoom(code: String) {
        db.collection("decks").document(code).delete()
        db.collection("rooms").document(code).delete()
    }

    // Film → Firestore mapi
    private static func deckEntry(_ movie: Movie) -> [String: Any] {
        [
            "id": movie.id,
            "title": movie.title,
            "posterPath": movie.posterPath as Any,
            "voteAverage": movie.voteAverage
        ]
    }
    
    // Bir swipe kaydet ilerlemeyi güncelle, beğendiyse film idsini likesa ekle
    func recordSwipe(code: String, uid: String, index: Int, likedMovieID: Int?) async throws {
        var data: [String: Any] = ["progress.\(uid)": index]
        if let likedMovieID {
            data["likes.\(uid)"] = FieldValue.arrayUnion([likedMovieID])
        }
        data["expiresAt"] = Self.expiry()   // aktivite oldukça oda ömrünü uzat (TTL tazele)
        try await db.collection("rooms").document(code).updateData(data)
    }

    // Bir eşleşmeyi "bu gece için" listesinden çıkar → iki oyuncuda da gizlenir
    func rejectMatch(code: String, movieID: Int) async throws {
        try await db.collection("rooms").document(code).updateData([
            "rejected": FieldValue.arrayUnion([movieID])
        ])
    }

    // Deste bitmeye yakın yeni sayfayı desteye ekle (mevcut olanları ekleme)
    func appendDeck(code: String, movies: [Movie], page: Int) async throws {
        let deckRef = db.collection("decks").document(code)
        // Mevcut desteyi oku → aynı filmi tekrar ekleme
        let snapshot = try await deckRef.getDocument()
        let existing = try? snapshot.data(as: DeckDoc.self)
        let existingIDs = Set((existing?.movies ?? []).map(\.id))
        let deckData = movies
            .filter { !existingIDs.contains($0.id) }
            .map(Self.deckEntry)
        guard !deckData.isEmpty else { return }
        try await deckRef.updateData([
            "movies": FieldValue.arrayUnion(deckData),
            "expiresAt": Self.expiry()
        ])
        try await db.collection("rooms").document(code).updateData([
            "deckPage": page,
            "expiresAt": Self.expiry()
        ])
    }

    // 6 haneli kod üretme. Demo koduna (000000) denk gelirse yeniden üret →
    // gerçek bir oda demo tetikleyici koduyla çakışmasın (join demo moda düşmesin).
    static func generateCode() -> String {
        var code: String
        repeat {
            let randomCode = Int.random(in: 0...999999) // 0 ile 999999 arası random bir code
            code = String(format: "%06d", randomCode)
        } while code == DemoMode.code
        return code
    }
 }

