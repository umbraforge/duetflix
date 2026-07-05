//
//  DeckMovie.swift
//  DuetFlix
//
//  Created by Batu on 5.07.2026.
//

import Foundation

// firestoreda kaydedeceğimiz film kartı

struct DeckMovie: Codable, Identifiable {
    let id: Int
    let title: String
    let posterPath: String?
    let voteAverage: Double
}

extension DeckMovie {
    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
}
