//
//  ModeSelectionView.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI

struct ModeSelectionView: View {
    let onSelect: (AppMode) -> Void // mod seçilince AppMode çağırılacak
    private let loc = LocalizationManager.shared

    var body: some View {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()
                Theme.ambientGlow.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xl) {
                    // Dil değiştirici (EN / TR)
                    HStack {
                        Spacer()
                        languageSwitcher
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.sm)

                    Spacer()

                    VStack(spacing: Theme.Spacing.sm) {
                        Text("DuetFlix")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.textPrimary)
                        Text(L("mode.question"))
                            .font(.headline)
                            .foregroundStyle(Color.textSecondary)
                    }

                    VStack(spacing: Theme.Spacing.md) {
                        // Solo
                        Button {
                            onSelect(.solo)
                        } label: {
                            modeCard(title: L("mode.solo.title"), subtitle: L("mode.solo.subtitle"),
                                     icon: "person.fill", highlighted: false)
                        }

                        // Duo
                        Button {
                            onSelect(.duo)
                        } label: {
                            modeCard(title: L("mode.duo.title"), subtitle: L("mode.duo.subtitle"),
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

    // EN / TR bayraklı seçici
    private var languageSwitcher: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(AppLanguage.allCases, id: \.self) { lang in
                Button {
                    loc.language = lang
                } label: {
                    HStack(spacing: 4) {
                        Text(lang.flag)
                        Text(lang.label).font(.caption.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(loc.language == lang ? Color.ember : Color.umbraSurface, in: Capsule())
                    .foregroundStyle(loc.language == lang ? Color.umbraBackground : Color.textSecondary)
                }
            }
        }
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
