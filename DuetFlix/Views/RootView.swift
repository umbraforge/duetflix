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

    var body: some View {
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
}
