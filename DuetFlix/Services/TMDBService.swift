//
//  TMDBService.swift
//  DuetFlix
//
//  Created by Batu on 1.07.2026.
//

import Foundation


protocol TMDBService {
    func fetchPopular() async throws -> [Movie] // zarfı açıp sadece film listesini döndürüyoruz
}


struct TMDBServiceLive : TMDBService {
    private let client = APIClient()
    
    func fetchPopular() async throws -> [Movie] {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular?language=en-US&page=1") else {throw APIError.invalidURL}
        
        let response : MovieResponse = try await client.fetch(url: url)
        return response.results
    }
}
