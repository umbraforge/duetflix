//
//  FilterView.swift
//  DuetFlix
//
//  Keşfet filtresi (Plus): tür + platform + süre + sıralama → sonuç ızgarası.
//  Bedava kullanıcı 2 kez uygulayabilir, sonra paywall.
//

import SwiftUI
import SwiftData   // .modelContainer (DetailView'in @Query'si için)

struct FilterView: View {
    @Environment(StoreService.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FilterViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        genreSection
                        providerSection
                        runtimeSection
                        sortSection
                        applySection
                        resultsSection
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
                    if !viewModel.filter.isDefault || !viewModel.results.isEmpty {
                        Button(L("filter.reset")) { viewModel.reset() }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView().environment(store)
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
                chip(r.label, selected: viewModel.filter.runtime == r) {
                    viewModel.toggleRuntime(r)
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

    // Uygula butonu + bedava hak bilgisi
    private var applySection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button {
                Task { await viewModel.apply(isPlus: store.isPlus) }
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

            if !store.isPlus {
                Text(viewModel.freeUsesLeft > 0
                     ? Lf("filter.free_left", viewModel.freeUsesLeft)
                     : L("filter.free_over"))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
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
                Task { await viewModel.apply(isPlus: store.isPlus) }
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
