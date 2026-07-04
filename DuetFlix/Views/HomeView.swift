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
    var onChangeMode: () -> Void = {}   // mod değiştir

    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea() // umbra zemin

                VStack(alignment: .leading, spacing: 0) {
                    // Başlık + mod değiştirme butonu
                    HStack {
                        Text("DuetFlix")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.textPrimary)

                        Spacer()

                        Button(action: onChangeMode) {
                            HStack(spacing: 6) {
                                Image(systemName: "rectangle.2.swap")
                                Text("Mod")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.ember)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.ember.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(Color.ember.opacity(0.3), lineWidth: 1))
                        }
                    }
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
                    .task {
                        // Sadece ilk açılışta yükle geri gelince tekrar yükleyip
                        // kaydırma konumunu sıfırlama
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
