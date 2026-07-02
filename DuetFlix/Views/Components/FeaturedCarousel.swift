//
//  FeaturedCarousel.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI

struct FeaturedCarousel: View {
    let movies: [Movie]
    @State private var currentID: Int?     // ortadaki kartın id'si

    var body: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(movies) { movie in
                        MovieCard(movie: movie)
                            .frame(width: 220)                 // 260 → 220 (küçülttük)
                            .scrollTransition { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.85)
                                    .opacity(phase.isIdentity ? 1.0 : 0.5)
                            }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 60)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentID, anchor: .center) // ortadaki kartı takip et
            .frame(height: 360)                                // 420 → 360

            // Sayfa noktaları
            HStack(spacing: 8) {
                ForEach(movies) { movie in
                    Circle()
                        .fill(movie.id == currentID ? Color.ember : Color.textSecondary.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
            }
        }
        .onAppear { currentID = movies.first?.id }             // ilk nokta aktif başlasın
    }
}

#Preview {
    // Gerçek posterli örnek filmler (Kingfisher gerçek URL'den indirir)
    let samples = [
        Movie(id: 1, title: "Dune", overview: "", posterPath: "/d5NXSklXo0qyIYkgV94XAgMIckC.jpg", voteAverage: 8.4, releaseDate: "2024"),
        Movie(id: 2, title: "Oppenheimer", overview: "", posterPath: "/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg", voteAverage: 8.1, releaseDate: "2023"),
        Movie(id: 3, title: "Barbie", overview: "", posterPath: "/iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg", voteAverage: 7.2, releaseDate: "2023")
    ]
    return FeaturedCarousel(movies: samples)
        .preferredColorScheme(.dark)
}
