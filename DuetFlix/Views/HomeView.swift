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
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                                    ForEach(movies) { movie in
                                        KFImage(movie.posterURL)
                                            .placeholder { Color.umbraSurface }   // yüklenene kadar
                                            .resizable()
                                            .aspectRatio(2/3, contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                                    }
                                }
                                .padding()
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
