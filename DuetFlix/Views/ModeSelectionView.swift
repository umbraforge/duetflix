//
//  ModeSelectionView.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI

struct ModeSelectionView: View {
    let onSelect: (AppMode) -> Void // mod seçilince AppMode çağırılacak
    
    var body: some View {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()
                Theme.ambientGlow.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()

                    VStack(spacing: Theme.Spacing.sm) {
                        Text("DuetFlix")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.textPrimary)
                        Text("How will you watch?")
                            .font(.headline)
                            .foregroundStyle(Color.textSecondary)
                    }

                    VStack(spacing: Theme.Spacing.md) {
                        // Solo
                        Button {
                            onSelect(.solo)
                        } label: {
                            modeCard(title: "Solo", subtitle: "Keşfet, filtrele, kaydet",
                                     icon: "person.fill", highlighted: false)
                        }

                        // Duo
                        Button {
                            onSelect(.duo)
                        } label: {
                            modeCard(title: "Duo", subtitle: "Birlikte eşleş",
                                     icon: "person.2.fill", highlighted: true)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    Spacer()
                    Text("UmbraForge")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .tint(.ember)
    }

    // Mod kartı 
    private func modeCard(title: String, subtitle: String, icon: String, highlighted: Bool) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(highlighted ? Color.umbraBackground : Color.ember)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title3.bold())
                Text(subtitle).font(.caption)
                    .foregroundStyle(highlighted ? Color.umbraBackground.opacity(0.7) : Color.textSecondary)
            }
            Spacer()
        }
        .foregroundStyle(highlighted ? Color.umbraBackground : Color.textPrimary)
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(highlighted ? Color.ember : Color.umbraSurface,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

#Preview {
    ModeSelectionView(onSelect: { _ in })
        .preferredColorScheme(.dark)
}
