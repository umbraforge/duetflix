//
//  Room.swift
//  DuetFlix
//
//  Created by Batu on 4.07.2026.
//

import Foundation
import FirebaseFirestore

// neden codable? firestore verisini swift'e çevirmek için
struct Room: Codable, Identifiable {
    @DocumentID var id: String? // oda kodu (döküman idsi), oda henüz kaydedilmemiş olabilir o yüzden optional
    var hostID: String
    var status: String
    var members: [String: String]   // uid (benzersiz anahtar) → isim (dostça etiket)
    var deckPage: Int?        // deste hangi sayfaya kadar dolduruldu (refill için)
    var playing: [String]?    // o an swipe ekranında olan oyuncuların uidleri (lobide olanlar burada değil)
    var progress: [String: Int]?   // uid → kaçıncı karttasın (devam edince kaldığı yerden)
    var likes: [String: [Int]]?    // uid → beğenilen film id'leri (eşleşme için)
    var rejected: [Int]?           // eşleşme listesinden çıkarılan film idleri
    var expiresAt: Date?           // TTL: bu zamandan sonra Firestore odayı otomatik siler
}

