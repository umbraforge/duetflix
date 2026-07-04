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
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration? // dinleyiciyi kayıt ettiriyoruzki sonradan kapatalım, kapatmazsak bellek sızıntısı !!!!
    
    // Odayı gerçek zamanlı dinleme
    func listen(code: String) {
        listener?.remove() // önceki listener varsa kapat
        listener = db.collection("rooms").document(code)
            .addSnapshotListener {[weak self] snapshot, error in // her değişiklikte ve o anki veriyle hemen dinlemeye başlar, weak self, listener sürekli açık böylece closure güçlü olur ve kapatılamaz retain cycle
                guard let self else {return}
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.room = try? snapshot?.data(as: Room.self) // firestore dökümanını rooma çöz
            }
    }
    
    // Ekrandan çıkınca dinlemeyi durdur
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
}
