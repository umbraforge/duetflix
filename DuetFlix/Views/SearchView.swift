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
                        ContentUnavailableView("Film ara",
                            systemImage: "magnifyingglass",
                            description: Text("Bir film adı yaz"))
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
            .navigationTitle("Keşfet")
            .searchable(text: $viewModel.query, prompt: "Film ara")
        }
        .tint(.ember)
    }
}

#Preview {
    SearchView()
        .preferredColorScheme(.dark)
}
