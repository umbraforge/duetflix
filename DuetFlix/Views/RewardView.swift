//
//  RewardView.swift
//  DuetFlix
//
//  Ödüllü reklam ekranı: reklam izle → filtre hakkı kazan.
//  Hak bitince bağlamsal olarak açılır, ayrıca Profil'den gönüllü açılabilir.
//

import SwiftUI

struct RewardView: View {
    @Environment(AdService.self) private var ads
    @Environment(FilterCredits.self) private var credits
    @Environment(\.dismiss) private var dismiss

    @State private var didEarn = false      // bu oturumda ödül kazanıldı mı
    @State private var didDecline = false   // reklam izlendi ama yarıda kapatıldı

    private let privacyURL = URL(string: "https://umbraforge.github.io/duetflix/site/privacy.html")!

    var body: some View {
        ZStack {
            Color.umbraBackground.ignoresSafeArea()
            Theme.ambientGlow.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    icon

                    VStack(spacing: Theme.Spacing.xs) {
                        Text(didEarn ? L("reward.earned_title") : L("reward.title"))
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(didEarn
                             ? Lf("reward.earned_subtitle", FilterCredits.rewardAmount)
                             : L("reward.subtitle"))
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    balanceCard
                    watchSection

                    Text(L("reward.why"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Link(L("reward.privacy"), destination: privacyURL)
                        .font(.caption)
                        .tint(Color.textSecondary)
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
        .task { await ads.preload() }   // ekran açılırken reklamı hazırla
    }

    // Ember kart + ikon (ödül alındıysa onay işareti)
    private var icon: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.umbraSurface)
            .overlay(
                Image(systemName: didEarn ? "checkmark.seal.fill" : "play.rectangle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color.ember)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.ember.opacity(0.3), lineWidth: 1)
            )
            .frame(width: 96, height: 96)
            .shadow(color: Color.ember.opacity(0.35), radius: 20, y: 6)
            .animation(.spring(duration: 0.4), value: didEarn)
    }

    // Mevcut bakiye
    private var balanceCard: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("\(credits.balance)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ember)
                .contentTransition(.numericText())
            Text(L("reward.balance_label"))
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(Color.umbraSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .animation(.spring(duration: 0.4), value: credits.balance)
    }

    // "Reklam izle" butonu + durum mesajları
    private var watchSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button {
                Task { await watchAd() }
            } label: {
                Group {
                    if ads.isPresenting || ads.state == .loading {
                        ProgressView().tint(Color.umbraBackground)
                    } else {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "play.fill")
                            Text(Lf("reward.watch", FilterCredits.rewardAmount))
                        }
                    }
                }
                .font(.headline)
                .foregroundStyle(Color.umbraBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.ember, in: Capsule())
                .shadow(color: Color.ember.opacity(0.4), radius: 12, y: 4)
            }
            .disabled(ads.isPresenting || ads.state == .loading)

            if ads.state == .unavailable {
                Text(L("reward.unavailable"))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            } else if didDecline {
                Text(L("reward.not_finished"))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if didEarn {
                Button(L("reward.continue")) { dismiss() }
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.ember)
            }
        }
    }

    private func watchAd() async {
        didDecline = false
        let earned = await ads.showRewarded()
        if earned {
            credits.grantReward()
            didEarn = true
        } else if ads.state != .unavailable {
            didDecline = true   // reklam açıldı ama sonuna kadar izlenmedi
        }
    }
}
