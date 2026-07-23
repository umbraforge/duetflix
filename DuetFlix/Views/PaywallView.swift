//
//  PaywallView.swift
//  DuetFlix
//
//  DuetFlix Plus satın alma ekranı (tek seferlik kilit). Bağlamsal olarak sunulur.
//

import SwiftUI
import StoreKit   // Product.displayPrice için

struct PaywallView: View {
    @Environment(StoreService.self) private var store
    @Environment(\.dismiss) private var dismiss

    // Apple zorunlu: satın alma ekranında şartlar + gizlilik linki
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://umbraforge.github.io/duetflix/site/privacy.html")!

    var body: some View {
        ZStack {
            Color.umbraBackground.ignoresSafeArea()
            Theme.ambientGlow.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    icon
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(L("paywall.title"))
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.textPrimary)
                        Text(L("paywall.subtitle"))
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    features

                    if store.isPlus {
                        activeState
                    } else {
                        buySection
                    }

                    legalLinks
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.lg)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(Theme.Spacing.md)
            .accessibilityLabel(L("a11y.close"))
        }
        .task { await store.loadProduct() }
    }

    // Ember daire + kalp/kilit
    private var icon: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.umbraSurface)
            .overlay(
                Image(systemName: "sparkles")
                    .font(.system(size: 42))
                    .foregroundStyle(Color.ember)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.ember.opacity(0.3), lineWidth: 1)
            )
            .frame(width: 96, height: 96)
            .shadow(color: Color.ember.opacity(0.35), radius: 20, y: 6)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            featureRow("line.3.horizontal.decrease.circle.fill", L("paywall.feature_filter"))
            featureRow("person.3.fill", L("paywall.feature_group"))
            featureRow("heart.fill", L("paywall.feature_support"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.lg)
        .background(Color.umbraSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.ember)
                .frame(width: 28)
            Text(text)
                .font(.callout)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // Satın alma bölümü (fiyat + buton + geri yükle)
    private var buySection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button {
                Task { await store.purchase() }
            } label: {
                Group {
                    if store.isPurchasing {
                        ProgressView().tint(Color.umbraBackground)
                    } else if let product = store.product {
                        Text(Lf("paywall.buy", product.displayPrice))
                    } else {
                        Text(L("paywall.buy_plain"))
                    }
                }
                .font(.headline)
                .foregroundStyle(Color.umbraBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.ember, in: Capsule())
                .shadow(color: Color.ember.opacity(0.4), radius: 12, y: 4)
            }
            .disabled(store.product == nil || store.isPurchasing)

            if store.product == nil {
                Text(L("paywall.unavailable"))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Text(L("paywall.once"))
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            Button(L("paywall.restore")) {
                Task { await store.restore() }
            }
            .font(.subheadline)
            .foregroundStyle(Color.ember)
        }
    }

    // Zaten Plus'a sahipse
    private var activeState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.ember)
            Text(L("paywall.active"))
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            Text(L("paywall.active_note"))
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Theme.Spacing.md)
    }

    private var legalLinks: some View {
        HStack(spacing: Theme.Spacing.md) {
            Link(L("paywall.terms"), destination: termsURL)
            Text("·").foregroundStyle(Color.textSecondary)
            Link(L("paywall.privacy"), destination: privacyURL)
        }
        .font(.caption)
        .tint(Color.textSecondary)
    }
}
