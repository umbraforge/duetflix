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
                eventMessage = "\(newMembers[id] ?? "Bir oyuncu") katıldı"
            }
            for id in left where id != myUID {
                eventMessage = "\(previousMembers[id] ?? "Bir oyuncu") çıktı"   // giden artık newMembersta yok ondan dolayı ismini previoustan alıyoruz
            }
        }
        previousMembers = newMembers
    }
    
    // Ekrandan çıkınca dinlemeyi durdur
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func leave(code: String, uid: String) async {
        let ref = db.collection("rooms").document(code)
        do {
            let isHost = room?.hostID == uid  // host muyum?
            let isLast = (room?.members.count ?? 0) <= 1 // lobbydeki son kişi miyim?
            
            if isHost || isLast {
                try await roomService.deleteRoom(code: code) // oda + deste alt-dokümanı
            } else {
                try await ref.updateData([ // sadece beni çıkar (map'ten uid anahtarını sil)
                    "members.\(uid)": FieldValue.delete()
                ])
            }
        } catch {
            print("Ayrılma hatası:", error)
        }
    }

    // Oyundan lobiye dön (odadan çıkma!): "playing"ten uid'i çıkar
    func exitToLobby(code: String, uid: String) async {
        do {
            try await db.collection("rooms").document(code).updateData([
                "playing": FieldValue.arrayRemove([uid])
            ])
        } catch {
            print("Lobiye dönüş hatası:", error)
        }
    }

    // Lobiden oyuna geri dön playinge uidi ekle
    func rejoin(code: String, uid: String) async {
        do {
            try await db.collection("rooms").document(code).updateData([
                "playing": FieldValue.arrayUnion([uid])
            ])
        } catch {
            print("Oyuna dönüş hatası:", error)
        }
    }

    // Host oyunu başlatır popüler filmleri çeker ve odaya deste olarak yazar, fetchPopular ile filmler çekiliyor ardından startGame ile firestore'a yazılıyor
    func startGame(code: String) async {
        guard !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        do {
            let movies = try await tmdb.fetchPopular(page: 1)     // ilk 20 popüler
            let players = Array((room?.members ?? [:]).keys)       // başlarken herkes oyunda
            try await roomService.startGame(code: code, movies: movies, page: 1, players: players)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
}
