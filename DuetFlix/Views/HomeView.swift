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
    @State private var surpriseID: Int?          // "Zar at" ile seçilen film → detay
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
                                Text(L("home.mode"))
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
                            ProgressView(L("common.loading"))
                        case .loaded:
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    surpriseButton   //  Zar at — karar yardımcısı

                                    FeaturedCarousel(movies: Array(viewModel.movies.prefix(10)))   // ilk 10 film öne çıkan

                                    MovieRow(title: L("home.popular"),
                                             movies: Array(viewModel.movies.dropFirst(10)),
                                             onReachEnd: { Task { await viewModel.loadMore() } })

                                    if viewModel.isLoadingMore {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                            .padding(.bottom)
                                    }

                                    // Mod / ruh hali satırları
                                    ForEach(viewModel.rows) { row in
                                        MovieRow(title: row.title, movies: row.movies)
                                    }
                                }
                                .padding(.bottom)
                            }
                        case .error(let message):
                            ErrorView(message: message) {
                                Task { await viewModel.loadHome() }
                            }
                        }
                    }
                    .task {
                        // Sadece ilk açılışta yükle geri gelince tekrar yükleyip
                        // kaydırma konumunu sıfırlama
                        if viewModel.movies.isEmpty {
                            await viewModel.loadHome()
                        }
                    }
                }
            }
            .navigationDestination(item: $surpriseID) { id in
                DetailView(movieID: id)
            }
        }
    }

    // 🎲 Zar at — yüklenen havuzdan rastgele film seç → detay ekranı
    private var surpriseButton: some View {
        Button {
            surpriseID = viewModel.surprisePick()?.id
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "die.face.5.fill")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("home.surprise")).font(.headline)
                    Text(L("home.surprise_sub"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.textSecondary)
            }
            .foregroundStyle(Color.ember)
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.ember.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Color.ember.opacity(0.3), lineWidth: 1))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
