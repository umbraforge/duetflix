//
//  ContentView.swift
//  DuetFlix
//
//  Created by Batu on 30.06.2026.
//

import SwiftUI

/// CP1 geçici demo: tasarım token'larının (renk/boşluk/köşe) çalıştığını gösterir.
/// CP4'te gerçek ana ekranla değişecek.
struct ContentView: View {
    var body: some View {
        ZStack {
            Color.umbraBackground.ignoresSafeArea()
            Theme.ambientGlow.ignoresSafeArea()

            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("DuetFlix")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.textPrimary)
                    Text("Design tokens & theme")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }

                // Renk paleti örnekleri
                HStack(spacing: Theme.Spacing.sm) {
                    swatch("Ember", .ember)
                    swatch("Surface", .umbraSurface)
                    swatch("Elevated", .umbraSurfaceElevated)
                }

                // Birincil buton (ember pill)
                Text("Watchlist'e ekle")
                    .font(.headline)
                    .foregroundStyle(Color.umbraBackground)
                    .padding(.vertical, Theme.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.ember, in: Capsule())

                // Puan satırı
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "star.fill").foregroundStyle(Color.ratingStar)
                    Text("8.4").foregroundStyle(Color.textPrimary)
                    Text("• 2026 • 128 min").foregroundStyle(Color.textSecondary)
                }
                .font(.subheadline)

                Spacer()
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(color)
                .frame(height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .stroke(Color.white.opacity(0.08))
                )
            Text(name)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
}
