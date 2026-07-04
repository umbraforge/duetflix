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
    func createRoom(hostID: String) async throws -> String {
        let code = Self.generateCode()
        try await db.collection("rooms").document(code).setData([
            "hostID": hostID,
            "status": "lobby",
            "createdAt": FieldValue.serverTimestamp(),
            "members": [hostID]
        ])
        return code
    }
    
    // Odaya katılma, members dizisine uid ekleme
    func joinRoom(code: String, uid: String) async throws {
        try await db.collection("rooms").document(code).updateData([
            "members": FieldValue.arrayUnion([uid])
        ])
    }
    
    // 6 haneli kod üretme
    static func generateCode() -> String {
        let randomCode = Int.random(in: 0...999999) // 0 ile 999999 arası random bir code
        let randomStringCode = String(format: "%06d", randomCode)
        
        return randomStringCode
    }
 }

