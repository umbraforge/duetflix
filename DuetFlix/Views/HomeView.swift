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
                            ProgressView("Yukleniyor")
                        case .loaded(let movies):
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    FeaturedCarousel(movies: Array(movies.prefix(5)))   // ilk 5 film öne çıkan

                                    MovieRow(title: "Popular", movies: Array(movies.dropFirst(5)))
                                    
                                }
                            }
                        case .error(let message):
                            Text("Hata: \(message)")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .task {                                  // ← Group'a bağlı, dışarıda
                        await viewModel.loadPopular()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
