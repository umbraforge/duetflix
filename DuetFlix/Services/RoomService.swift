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

@MainActor
@Observable
final class RoomService {
    private let db = Firestore.firestore()
    
    // Oda kurma, kod üretme, firestore'a yazma, kodu döndür
    func createRoom(hostID: String, hostName: String) async throws -> String {
        let code = Self.generateCode()
        try await db.collection("rooms").document(code).setData([
            "hostID": hostID,
            "status": "lobby",
            "createdAt": FieldValue.serverTimestamp(),
            "members": [hostID: hostName]   // uid → isim
        ])
        return code
    }

    // Odaya katılma members mapine uid = isim ekleme
    // "members.\(uid)" = map içindeki tek bir anahtarı ayarlar 
    func joinRoom(code: String, uid: String, name: String) async throws {
        try await db.collection("rooms").document(code).updateData([
            "members.\(uid)": name
        ])
    }

    // Odayı bir kez çek (yoksa nil). Hem "oda var mı" hem "isim dolu mu" kontrolü için.
    func fetchRoom(code: String) async throws -> Room? {
        let snapshot = try await db.collection("rooms").document(code).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: Room.self)
    }
    
    // Host oyunu başlatır desteyi yaz + statusü swiping yap + tüm oyuncuları "playing"e ekle
    func startGame(code: String, movies: [Movie], page: Int, players: [String]) async throws {
        let deckData = movies.map { movie in
            [
                "id": movie.id,
                "title": movie.title,
                "posterPath": movie.posterPath as Any,
                "voteAverage": movie.voteAverage
            ]
        }
        try await db.collection("rooms").document(code).updateData([ // status deck deckPage ve playing alanlarını güncelliyoruz
            "status": "swiping",
            "deck": deckData,
            "deckPage": page,
            "playing": players
        ])
    }
    
    // Bir swipe kaydet ilerlemeyi güncelle, beğendiyse film idsini likesa ekle
    func recordSwipe(code: String, uid: String, index: Int, likedMovieID: Int?) async throws {
        var data: [String: Any] = ["progress.\(uid)": index]
        if let likedMovieID {
            data["likes.\(uid)"] = FieldValue.arrayUnion([likedMovieID])
        }
        try await db.collection("rooms").document(code).updateData(data)
    }

    // Deste bitmeye yakın yeni sayfayı desteye ekle (mevcut olanları ekleme)
    func appendDeck(code: String, movies: [Movie], page: Int) async throws {
        let ref = db.collection("rooms").document(code)
        let snapshot = try await ref.getDocument()
        let existing = try? snapshot.data(as: Room.self)
        let existingIDs = Set((existing?.deck ?? []).map(\.id))
        let deckData = movies
            .filter { !existingIDs.contains($0.id) }
            .map { movie -> [String: Any] in
                [
                    "id": movie.id,
                    "title": movie.title,
                    "posterPath": movie.posterPath as Any,
                    "voteAverage": movie.voteAverage
                ]
            }
        guard !deckData.isEmpty else { return }
        try await ref.updateData([
            "deck": FieldValue.arrayUnion(deckData),
            "deckPage": page
        ])
    }

    // 6 haneli kod üretme
    static func generateCode() -> String {
        let randomCode = Int.random(in: 0...999999) // 0 ile 999999 arası random bir code
        let randomStringCode = String(format: "%06d", randomCode)
        
        return randomStringCode
    }
 }

