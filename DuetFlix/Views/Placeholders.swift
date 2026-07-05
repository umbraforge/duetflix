//
//  Placeholders.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        PlaceholderScreen(title: "Profil", subtitle: "Yakında")
    }
}

struct SwipeView: View {
    let code: String
    let uid: String

    var body: some View {
        ZStack {
            Color.umbraBackground.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.md) {
                Text("Oyun Başladı!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ember)
                Text("Kaydırma ekranı CP13'te gelecek")
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

struct DuoPlaceholder: View {
    let onChangeMode: () -> Void

    var body: some View {
        ZStack {
            Color.umbraBackground.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.lg) {
                Text("Duo")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.textPrimary)
                Text("Eşleştirme yakında (Faz 2)")
                    .foregroundStyle(Color.textSecondary)
                Button("Mod değiştir", action: onChangeMode)
                    .foregroundStyle(Color.ember)
            }
        }
    }
}
// Ortak placeholder görünümü
struct PlaceholderScreen: View {
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            Color.umbraBackground.ignoresSafeArea()
            VStack(spacing: 8) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

#Preview {
    SearchView()
        .preferredColorScheme(.dark)
}
