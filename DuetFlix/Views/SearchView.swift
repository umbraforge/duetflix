//
//  SearchView.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI

struct SearchView: View {
    @Environment(AdService.self) private var ads
    @Environment(FilterCredits.self) private var credits
    @State private var viewModel = SearchViewModel()
    @State private var showFilter = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()

                Group {
                    if viewModel.query.isEmpty {
                        // Henüz arama yok
                        ContentUnavailableView {
                            Label(L("search.empty.title"), systemImage: "magnifyingglass")
                        } description: {
                            Text(L("search.empty.desc"))
                        }
                    } else if viewModel.didFail && viewModel.results.isEmpty && !viewModel.isSearching {
                        // Ağ hatası — "sonuç yok" ile karıştırma
                        ErrorView(message: L("search.error")) { viewModel.retry() }
                    } else if viewModel.results.isEmpty && !viewModel.isSearching {
                        // Sonuç yok
                        ContentUnavailableView.search(text: viewModel.query)
                    } else {
                        // Sonuç listesi
                        ScrollView {
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
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle(L("tab.discover"))
            .searchable(text: $viewModel.query, prompt: L("search.empty.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel(L("filter.title"))
                }
            }
            .sheet(isPresented: $showFilter) {
                // sheet environment'ı miras almaz → reklam + hak nesnelerini açıkça ver
                FilterView().environment(ads).environment(credits)
            }
        }
        .tint(.ember)
    }
}

#Preview {
    SearchView()
        .environment(AdService())
        .environment(FilterCredits())
        .preferredColorScheme(.dark)
}
