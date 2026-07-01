//
//  Movie.swift
//  DuetFlix
//
//  Created by Batu on 1.07.2026.
//

import Foundation



struct Movie: Codable , Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String? // bazı filmlerin posterleri yok null dönebiliyor
    let voteAverage: Double
    let releaseDate: String
    
    // json'da gelen verilen değişkenleriyle burdakileri eşleştirmek için istersek snake_case yaparak da çözebiliriz.
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
    }
}

// posterpath yoksa nil döndürmek için ekledik, eğer path varsa url'si hazır
extension Movie {
    var posterURL: URL? {
        guard let posterPath else {return nil} // posteri yoksa nil
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
}

struct MovieResponse: Codable {
    let page: Int
    let results: [Movie] // sonuçlar bir film dizisi
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
    
}
