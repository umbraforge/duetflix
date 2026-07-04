//
//  RootView.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI

enum AppMode {
    case solo
    case duo
}

struct RootView: View {
    @State private var mode: AppMode? = nil 
    @State private var auth = AuthService() // giriş için kullanılan service
    var body: some View {
        Group {
            switch mode {
            case .none:
                // Mod seçilmedi → seçim ekranı. Seçilince mode'u güncelle.
                ModeSelectionView(onSelect: { selected in
                    mode = selected
                })
            case .solo:
                // Solo → tab bar. "Mod değiştir" deyince mode'u sıfırla.
                MainTabView(onChangeMode: { mode = nil })
            case .duo:
                if let uid = auth.uid { // oda kurarken auth.id lazım auth biraz gecikebilir uid gelene kadar progressView.keyboardType(.numberPad)
                    DuoView(uid: uid, onChangeMode: {mode = nil})
                } else {
                    ProgressView() // auth tamamlanmadığı zaman
                }
            }
        }
        .task {
            await auth.signInIfNeeded() // service üzerinden giriş veya hazır user id çek (anonim)
        }
    }
}
