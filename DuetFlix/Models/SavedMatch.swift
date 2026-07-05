//
//  SavedMatch.swift
//  DuetFlix
//
//  Eşleşen (ikinizin de beğendiği) filmler cihazda kalıcı saklanır — oda kapansa
//  bile "geçmiş eşleşmeler" kaybolmasın. Watchlist ile aynı SwiftData deseni.
//

import Foundation
import SwiftData

@Model
final class SavedMatch {
    var movieID: Int
    var title: String
    var posterPath: String?
    var voteAverage: Double
    var matchedAt: Date
    var roomCode: String = ""    // hangi oturumda odada eşleşildi — geçmişi gruplamak için
    var partners: [String] = []  // o oturumda lobideki isimler

    init(movieID: Int, title: String, posterPath: String?, voteAverage: Double,
         roomCode: String, partners: [String]) {
        self.movieID = movieID
        self.title = title
        self.posterPath = posterPath
        self.voteAverage = voteAverage
        self.matchedAt = Date()
        self.roomCode = roomCode
        self.partners = partners
    }
}

extension SavedMatch {
    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
}
