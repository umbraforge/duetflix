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
    
    // 6 haneli kod üretme
    static func generateCode() -> String {
        let randomCode = Int.random(in: 0...999999) // 0 ile 999999 arası random bir code
        let randomStringCode = String(format: "%06d", randomCode)
        
        return randomStringCode
    }
 }

