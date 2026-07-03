//
//  WatchListItem.swift
//  DuetFlix
//
//  Created by Batu on 3.07.2026.
//

import Foundation
import SwiftData

@Model
final class WatchlistItem {
    var movieID: Int
    var title: String
    var posterPath: String?
    var voteAverage: Double
    var addedAt: Date

    init(movieID: Int, title: String, posterPath: String?, voteAverage: Double) {
        self.movieID = movieID
        self.title = title
        self.posterPath = posterPath
        self.voteAverage = voteAverage
        self.addedAt = Date()
    }
}

extension WatchlistItem {
    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
}
