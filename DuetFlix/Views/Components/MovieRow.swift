//
//  MovieRow.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI

struct MovieRow: View {
    let title: String
    let movies: [Movie]
    var onReachEnd: () -> Void = {}   // son karta gelince çağrılır (varsayılan: boş)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                // HStack = tüm kartlar baştan çizilir → akıcı kaydırma
                HStack(spacing: 12) {
                    ForEach(movies) { movie in
                        NavigationLink {
                            DetailView(movieID: movie.id)      // gidilecek ekran
                        } label: {
                            MovieCard(movie: movie)            // tıklanacak görünüm
                                .frame(width: 120)
                        }
                    }
                }
                .padding(.horizontal)
            }
            // Tetiği .onAppear yerine gerçek kaydırma konumundan al:
            // sağdaki sona ~400pt kala "yaklaştı" olur.
            .onScrollGeometryChange(for: Bool.self) { geo in
                geo.contentOffset.x + geo.containerSize.width >= geo.contentSize.width - 400
            } action: { wasNearEnd, isNearEnd in
                if isNearEnd && !wasNearEnd { onReachEnd() }   // sadece "yaklaştı"ya geçişte tetikle
            }
        }
    }
}

#Preview {
    // Gerçek posterli örnek filmler (Kingfisher canvas'ta indirir)
    let samples = [
        Movie(id: 1, title: "Dune", overview: "", posterPath: "/d5NXSklXo0qyIYkgV94XAgMIckC.jpg", voteAverage: 8.4, releaseDate: "2024"),
        Movie(id: 2, title: "Oppenheimer", overview: "", posterPath: "/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg", voteAverage: 8.1, releaseDate: "2023"),
        Movie(id: 3, title: "Barbie", overview: "", posterPath: "/iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg", voteAverage: 7.2, releaseDate: "2023")
    ]
    return ZStack {
        Color.umbraBackground.ignoresSafeArea()
        MovieRow(title: "Popüler", movies: samples)
    }
    .preferredColorScheme(.dark)
}
