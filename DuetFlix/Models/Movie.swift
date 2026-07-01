//
//  Movie.swift
//  DuetFlix
//
//  Created by Batu on 1.07.2026.
//

// Codable = JSON'a çevrilebilir / üretilebilir. JSONDecoder bu alanları otomatik doldurur
// Identifiable = her filmin benzersiz kimliği için id tanımlamasını zorunlu kılar
// json'dan gelen metni, swift tipine çeviriyor
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
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") // poster'in url'si 
    }
}

// zarf, Movie = zarfın içindeki filmler
struct MovieResponse: Codable {
    let page: Int
    let results: [Movie] // asıl filmler burada
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
