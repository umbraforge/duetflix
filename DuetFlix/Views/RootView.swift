//
//  RootView.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI
import FirebaseAuth

enum AppMode {
    case solo
    case duo
}

struct RootView: View {
    @State private var mode: AppMode? = nil 

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
                DuoPlaceholder(onChangeMode: { mode = nil })
            }
        }
        .task {
            do {
                let result = try await Auth.auth().signInAnonymously() // Auth.auth() firebase'in giriş nesnesi, signAnon ile anon şekilde giriyoruz ve result olarak firebase benzersiz id veriyor, o cihaz için kalıcı
                print("Anonim giriş başarılı, uid:", result.user.uid)
            } catch {
                print("Giriş hatası:", error)
            }
        }
    }
}
