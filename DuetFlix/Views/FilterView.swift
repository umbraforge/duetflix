//
//  FilterView.swift
//  DuetFlix
//
//  Keşfet filtresi: tür + platform + süre + puan + sıralama → sonuç ızgarası.
//  Her uygulama bir filtre hakkı yakar; hak bitince ödüllü reklamla kazanılır.
//

import SwiftUI
import SwiftData   // .modelContainer (DetailView'in @Query'si için)

struct FilterView: View {
    @Environment(AdService.self) private var ads
    @Environment(FilterCredits.self) private var credits
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FilterViewModel()
    @State private var editing = true   // true: filtre seçimi · false: sonuç ızgarası

    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        if editing {
                            genreSection
                            providerSection
                            runtimeSection
                            ratingSection
                            sortSection
                            applySection
                        } else {
                            resultsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(L("filter.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("common.close")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if editing {
                        if !viewModel.filter.isDefault {
                            Button(L("filter.reset")) { viewModel.reset() }
                        }
                    } else {
                        // Sonuçlardayken filtreye geri dön (seçimler + sonuçlar korunur)
                        Button(L("filter.edit")) { editing = true }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showReward) {
                RewardView().environment(ads).environment(credits)
            }
        }
        .tint(.ember)
        .modelContainer(AppDatabase.shared)   // sheet → DetailView'in izleme listesi için
    }

    // MARK: - Bölümler

    private var genreSection: some View {
        section(L("filter.genre")) {
            chipRow(FilterGenre.all) { g in
                chip(g.name, selected: viewModel.filter.genres.contains(g.id)) {
                    viewModel.toggleGenre(g.id)
                }
            }
        }
    }

    private var providerSection: some View {
        section(L("filter.platform")) {
            chipRow(FilterProvider.all) { p in
                chip(p.name, selected: viewModel.filter.providers.contains(p.id)) {
                    viewModel.toggleProvider(p.id)
                }
            }
        }
    }

    private var runtimeSection: some View {
        section(L("filter.runtime")) {
            chipRow(RuntimeRange.allCases) { r in
                chip(r.label, selected: viewModel.filter.runtimes.contains(r)) {
                    viewModel.toggleRuntime(r)
                }
            }
        }
    }

    private var ratingSection: some View {
        section(L("filter.rating")) {
            chipRow(MinRating.allCases) { r in
                chip(r.label, selected: viewModel.filter.minRating == r) {
                    viewModel.toggleRating(r)
                }
            }
        }
    }

    private var sortSection: some View {
        section(L("filter.sort")) {
            chipRow(MovieSort.allCases) { s in
                chip(L(s.labelKey), selected: viewModel.filter.sort == s) {
                    viewModel.filter.sort = s
                }
            }
        }
    }

    // Uygula butonu + kalan hak bilgisi
    private var applySection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button {
                Task {
                    await viewModel.apply(credits: credits)
                    if !viewModel.showReward { editing = false }   // sonuç geldi → filtreyi kapat
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    if viewModel.state == .loading {
                        ProgressView().tint(Color.umbraBackground)
                    } else {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    }
                    Text(L("filter.apply"))
                }
                .font(.headline)
                .foregroundStyle(Color.umbraBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.ember, in: Capsule())
                .shadow(color: Color.ember.opacity(0.4), radius: 12, y: 4)
            }
            .disabled(viewModel.state == .loading)

            // Kalan hak — bitince "reklam izle" ipucu
            Text(credits.isEmpty
                 ? L("filter.credits_over")
                 : Lf("filter.credits_left", credits.balance))
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // Sonuçlar
    @ViewBuilder
    private var resultsSection: some View {
        switch viewModel.state {
        case .idle:
            Text(L("filter.idle_hint"))
                .font(.callout)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, Theme.Spacing.xl)
        case .loading:
            EmptyView()
        case .empty:
            ContentUnavailableView {
                Label(L("filter.empty"), systemImage: "film.stack")
            }
        case .error:
            ErrorView(message: L("search.error")) {
                Task { await viewModel.apply(credits: credits) }
            }
        case .loaded:
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(viewModel.results) { movie in
                    NavigationLink {
                        DetailView(movieID: movie.id)
                    } label: {
                        MovieCard(movie: movie)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Yardımcılar

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            content()
        }
    }

    // Yatay kaydırılan chip satırı
    private func chipRow<T: Identifiable, Chip: View>(_ items: [T],
                                                      @ViewBuilder _ chip: @escaping (T) -> Chip) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(items) { item in chip(item) }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.caption.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Color.ember : Color.umbraSurface, in: Capsule())
                .foregroundStyle(selected ? Color.umbraBackground : Color.textPrimary)
        }
        .buttonStyle(.plain)
    }
}
