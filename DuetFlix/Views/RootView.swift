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
    @State private var pendingJoinCode: String?   // deep link'ten gelen oda kodu

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
                if let uid = auth.uid { // oda kurarken auth.id lazım auth biraz gecikebilir uid gelene kadar progressView
                    DuoView(uid: uid, initialCode: pendingJoinCode, onChangeMode: { mode = nil })
                } else {
                    ProgressView() // auth tamamlanmadığı zaman
                }
            }
        }
        .task {
            await auth.signInIfNeeded() // service üzerinden giriş veya hazır user id çek (anonim)
        }
        // duetflix://join?code=xxxxxx linki gelince Duo'ya geç + kodu doldur
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "duetflix", url.host == "join" else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value else { return }
        pendingJoinCode = code   // DuoView'da oda kodu kutusuna dolacak
        mode = .duo              // Duo ekranına geç
    }
}
