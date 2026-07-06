//
//  AuthService.swift
//  DuetFlix
//
//  Created by Batu on 4.07.2026.
//

import Foundation
import FirebaseAuth

@MainActor // id değişince view'da değişmesi için
@Observable
final class AuthService {
    private(set) var uid: String?
    
    // zaten girişliyse uid al değilse anonim giriş yap
    func signInIfNeeded() async {
        if let user = Auth.auth().currentUser { // şu an girişli bir user var mı?
            uid = user.uid
            return
        }
        
        // giriş yapılmadıysa anonim giriş yap
        do {
            let result = try await Auth.auth().signInAnonymously() // anonim giriş yap
            uid = result.user.uid
        } catch {
            // Anonim giriş başarısız — uid nil kalır, Duo ekranı denemeyi tekrar tetikler
        }
    }
}
