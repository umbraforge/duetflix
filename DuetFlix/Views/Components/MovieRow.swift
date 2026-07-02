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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(movies) { movie in
                        MovieCard(movie: movie)
                            .frame(width: 120)
                    }
                }
                .padding(.horizontal)
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
        MovieRow(title: "Popular", movies: samples)
    }
    .preferredColorScheme(.dark)
}
