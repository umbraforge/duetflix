//
//  ProfileView.swift
//  DuetFlix
//
//  Hakkında ekranı: uygulama sürümü, dil değiştirici (EN/TR),
//  TMDB atfı (App Store için zorunlu) ve stüdyo bilgisi.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AdService.self) private var ads
    @Environment(FilterCredits.self) private var credits
    @State private var showReward = false
    private let loc = LocalizationManager.shared

    // Bundledan sürüm + build numarası
    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()
                Theme.ambientGlow.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        header
                        creditsCard
                        languageCard
                        aboutCard
                        Spacer(minLength: Theme.Spacing.lg)
                        Text("UmbraForge")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .padding(.bottom, Theme.Spacing.md)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                }
            }
            .navigationTitle(L("tab.profile"))
            .sheet(isPresented: $showReward) {
                // sheet environment'ı miras almaz → nesneleri açıkça ver
                RewardView().environment(ads).environment(credits)
            }
        }
        .tint(.ember)
    }

    // Filtre hakkı kartı: bakiyeyi gösterir, dokununca ödüllü reklam ekranını açar
    private var creditsCard: some View {
        Button { showReward = true } label: {
            card {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.ember)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("profile.credits_title"))
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        Text(Lf("profile.credits_tagline", credits.balance))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // Header (logo + isim + stüdyo)
    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.umbraSurface)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.ember)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.ember.opacity(0.25), lineWidth: 1)
                )
                .frame(width: 88, height: 88)

            Text("DuetFlix")
                .font(.title.bold())
                .foregroundStyle(Color.textPrimary)
            Text(L("profile.made_by"))
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.top, Theme.Spacing.lg)
    }

    // Dil kartı
    private var languageCard: some View {
        card {
            HStack {
                Label(L("profile.language"), systemImage: "globe")
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                languageSwitcher
            }
        }
    }

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
                    .background(loc.language == lang ? Color.ember : Color.umbraBackground, in: Capsule())
                    .foregroundStyle(loc.language == lang ? Color.umbraBackground : Color.textSecondary)
                }
            }
        }
    }

    // Hakkında kartı (sürüm + TMDB atfı)
    private var aboutCard: some View {
        card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Text(L("profile.version")).foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text(appVersion).foregroundStyle(Color.textSecondary)
                }

                Divider().overlay(Color.white.opacity(0.06))

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(L("profile.data_source"))
                        .font(.caption.bold())
                        .foregroundStyle(Color.textSecondary)
                    // TMDB logosu (Assets'e "TMDBLogo" olarak eklenecek — yoksa boş görünür)
                    Image("TMDBLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(L("profile.tmdb_attr"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // Ortak kart sarmalayıcı
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.umbraSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

#Preview {
    ProfileView()
        .environment(AdService())
        .environment(FilterCredits())
        .preferredColorScheme(.dark)
}
