//
//  SearchView.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()

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
        }
        .tint(.ember)
    }
}

#Preview {
    SearchView()
        .preferredColorScheme(.dark)
}
