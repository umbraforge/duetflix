//
//  TMDBService.swift
//  DuetFlix
//
//  Created by Batu on 1.07.2026.
//

import Foundation

// sözleşme
protocol TMDBService {
    func fetchPopular() async throws -> [Movie] // zarfı açıp sadece film listesini döndürüyoruz
    func fetchDetail(id: Int) async throws -> MovieDetail // film id'sini alır ve detayını getirir
}

// Service, URL kurar client'e verir ve zarfı açar
struct TMDBServiceLive : TMDBService {
    private let client = APIClient()
    
    // popüler filmleri getirir
    func fetchPopular() async throws -> [Movie] {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular?language=en-US&page=1") else {throw APIError.invalidURL}
        
        // fetch T tipi döndürüyor, burda response : MovieResponse yaptığımızda T = MovieResponse olur
        let response : MovieResponse = try await client.fetch(url: url) // response : MovieResponse demezsek fetch T tipini bilemez
        return response.results // zarfı aç, sadece filmleri ver
    }
    func fetchDetail(id: Int) async throws -> MovieDetail {
        guard let url = URL(string:
            "https://api.themoviedb.org/3/movie/\(id)?language=en-US&append_to_response=credits,watch/providers")
        else { throw APIError.invalidURL }

        return try await client.fetch(url: url)
    }
}
