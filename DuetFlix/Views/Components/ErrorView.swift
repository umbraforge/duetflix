//
//  ErrorView.swift
//  DuetFlix
//
//  Hata durumları için ortak görünüm: mesaj + "Tekrar dene" butonu.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Color.textSecondary)

            Text("Bir şeyler ters gitti")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            Text(message)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Button("Tekrar dene", action: retry)
                .font(.headline)
                .foregroundStyle(Color.umbraBackground)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Color.ember, in: Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    ZStack {
        Color.umbraBackground.ignoresSafeArea()
        ErrorView(message: "İnternet bağlantısı yok.", retry: {})
    }
    .preferredColorScheme(.dark)
}
