//
//  DeckFilterSheet.swift
//  DuetFlix
//
//  Lobide host'un deste filtresini seçtiği kompakt sayfa. Sonuç ızgarası yok;
//  seçim doğrudan bağlı MovieFilter'a yazılır, "Tamam" ile kapanır.
//

import SwiftUI

struct DeckFilterSheet: View {
    @Binding var filter: MovieFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        section(L("filter.genre")) {
                            chipRow(FilterGenre.all) { g in
                                chip(g.name, filter.genres.contains(g.id)) { toggle(&filter.genres, g.id) }
                            }
                        }
                        section(L("filter.platform")) {
                            chipRow(FilterProvider.all) { p in
                                chip(p.name, filter.providers.contains(p.id)) { toggle(&filter.providers, p.id) }
                            }
                        }
                        section(L("filter.runtime")) {
                            chipRow(RuntimeRange.allCases) { r in
                                chip(r.label, filter.runtimes.contains(r)) { toggle(&filter.runtimes, r) }
                            }
                        }
                        section(L("filter.rating")) {
                            chipRow(MinRating.allCases) { r in
                                chip(r.label, filter.minRating == r) {
                                    filter.minRating = (filter.minRating == r) ? nil : r
                                }
                            }
                        }
                        section(L("filter.sort")) {
                            chipRow(MovieSort.allCases) { s in
                                chip(L(s.labelKey), filter.sort == s) { filter.sort = s }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(L("lobby.deck_filter"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !filter.isDefault { Button(L("filter.reset")) { filter = MovieFilter() } }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) { dismiss() }
                }
            }
        }
        .tint(.ember)
    }

    // MARK: - Yardımcılar

    private func toggle<T: Hashable>(_ set: inout Set<T>, _ value: T) {
        if set.contains(value) { set.remove(value) } else { set.insert(value) }
    }

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title).font(.headline).foregroundStyle(Color.textPrimary)
            content()
        }
    }

    private func chipRow<T: Identifiable, Chip: View>(_ items: [T],
                                                      @ViewBuilder _ chip: @escaping (T) -> Chip) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(items) { item in chip(item) }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(_ text: String, _ selected: Bool, action: @escaping () -> Void) -> some View {
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
