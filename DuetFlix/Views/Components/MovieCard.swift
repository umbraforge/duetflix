//
//  MovieCard.swift
//  DuetFlix
//
//  Created by Batu on 1.07.2026.
//

import SwiftUI
import Kingfisher

// Movie'yi alır kendisi posteri çizer
struct MovieCard: View {
    let movie: Movie // dışarıdan bir movie alınır,
    
    
    var body: some View {
        KFImage(movie.posterURL)
            .placeholder { Color.umbraSurface }
            .resizable()
            .aspectRatio(2/3, contentMode: .fit)
            .overlay(alignment: .bottom) {
                // Alttan yukarı karartma — yazı okunsun
                LinearGradient(
                    colors: [.black.opacity(0.85), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(movie.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.ratingStar)
                            Text(String(format: "%.1f", movie.voteAverage))
                                .foregroundStyle(Color.textPrimary)
                        }
                        .font(.caption.bold())
                    }
                    .padding(10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

#Preview {
    MovieCard(movie: Movie(
            id: 1, title: "Test", overview: "",
            posterPath: nil, voteAverage: 8.4, releaseDate: "2026"
        ))
        .frame(width: 150)
        .preferredColorScheme(.dark)
}
