//
//  TMDBService.swift
//  DuetFlix
//
//  Created by Batu on 1.07.2026.
//

import Foundation

// sözleşme
protocol TMDBService {
    func fetchPopular(page: Int) async throws -> [Movie] // zarfı açıp sadece film listesini döndürüyoruz
    func fetchDetail(id: Int) async throws -> MovieDetail // film id'sini alır ve detayını getirir
    func fetchSearch(query: String) async throws -> [Movie] // aramalarda kullanılacak fonksiyon
}

// Service, URL kurar client'e verir ve zarfı açar
struct TMDBServiceLive : TMDBService {
    private let client = APIClient()
    
    // popüler filmleri getirir
    func fetchPopular(page: Int) async throws -> [Movie] {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular?language=en-US&page=\(page)") else {throw APIError.invalidURL}
        
        // fetch T tipi döndürüyor, burda response : MovieResponse yaptığımızda T = MovieResponse olur
        let response : MovieResponse = try await client.fetch(url: url) // response : MovieResponse demezsek fetch T tipini bilemez
        return response.results // zarfı aç, sadece filmleri ver
    }
    // filmlerin detaylarını çeker
    func fetchDetail(id: Int) async throws -> MovieDetail {
        guard let url = URL(string:
            "https://api.themoviedb.org/3/movie/\(id)?language=en-US&append_to_response=credits,watch/providers,translations")
        else { throw APIError.invalidURL }

        return try await client.fetch(url: url)
    }
    // search edilen filmi getirir
    func fetchSearch(query: String) async throws -> [Movie] {
        guard var components = URLComponents(string: "https://api.themoviedb.org/3/search/movie") // kullanıcı boşluk girebilir, parça parça kuralım URLComponents ile
        else { throw APIError.invalidURL }

        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "language", value: "en-US"),   // orijinal başlık/poster
            URLQueryItem(name: "page", value: "1")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let response: MovieResponse = try await client.fetch(url: url)
        return response.results
    }
}
