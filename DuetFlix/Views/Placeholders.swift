//
//  Placeholders.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI

struct ProfileView: View {
    let onChangeMode: () -> Void

    var body: some View {
        ZStack {
            Color.umbraBackground.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.lg) {
                Text("Profil")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.textPrimary)
                Button("Mod değiştir", action: onChangeMode)
                    .font(.headline)
                    .foregroundStyle(Color.umbraBackground)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Color.ember, in: Capsule())
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
