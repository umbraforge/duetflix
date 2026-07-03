//
//  HomeView.swift
//  DuetFlix
//
//  Created by Batu on 1.07.2026.
//

import SwiftUI
import Kingfisher

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()   // umbra zemin
                
                VStack(alignment: .leading, spacing: 0) {
                    // Kendi başlığımız
                    Text("DuetFlix")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.textPrimary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    Group {
                        switch viewModel.state {
                        case .loading:
                            ProgressView("Yükleniyor")
                        case .loaded:
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    FeaturedCarousel(movies: Array(viewModel.movies.prefix(5)))   // ilk 5 film öne çıkan

                                    MovieRow(title: "Popüler",
                                             movies: Array(viewModel.movies.dropFirst(5)),
                                             onReachEnd: { Task { await viewModel.loadMore() } })

                                    if viewModel.isLoadingMore {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                            .padding(.bottom)
                                    }
                                }
                            }
                        case .error(let message):
                            ErrorView(message: message) {
                                Task { await viewModel.loadPopular() }
                            }
                        }
                    }
                    .task {                                  // ← Group'a bağlı, dışarıda
                        // Sadece ilk açılışta yükle; geri gelince tekrar yükleyip
                        // kaydırma konumunu sıfırlama.
                        if viewModel.movies.isEmpty {
                            await viewModel.loadPopular()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
