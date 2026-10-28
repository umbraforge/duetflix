//
//  TMDBService.swift
//  DuetFlix
//
//  Created by Batu on 1.07.2026.
//

import Foundation

// sözleşme (Sendable → tür satırlarını paralel/task group içinde güvenle çekebiliriz)
protocol TMDBService: Sendable {
    func fetchPopular(page: Int) async throws -> [Movie] // zarfı açıp sadece film listesini döndürüyoruz
    func fetchDetail(id: Int) async throws -> MovieDetail // film id'sini alır ve detayını getirir
    func fetchSearch(query: String) async throws -> [Movie] // aramalarda kullanılacak fonksiyon
    func fetchDiscover(filter: MovieFilter, page: Int) async throws -> [Movie]      // filtreli keşif
    func fetchDiscover(params: DiscoverParams, page: Int) async throws -> [Movie]   // çözülmüş parametrelerle (refill)
    func fetchMood(_ mood: HomeMood, page: Int) async throws -> [Movie]             // ana ekran mod satırı
}

// Service, URL kurar client'e verir ve zarfı açar
struct TMDBServiceLive : TMDBService {
    private let client = APIClient()
    
    // popüler filmleri getirir
    func fetchPopular(page: Int) async throws -> [Movie] {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/popular?language=en-US&page=\(page)&include_adult=false") else {throw APIError.invalidURL}
        
        // fetch T tipi döndürüyor, burda response : MovieResponse yaptığımızda T = MovieResponse olur
        let response : MovieResponse = try await client.fetch(url: url) // response : MovieResponse demezsek fetch T tipini bilemez
        return response.results // zarfı aç, sadece filmleri ver
    }
    // filmlerin detaylarını çeker
    func fetchDetail(id: Int) async throws -> MovieDetail {
        // videos: fragman listesi. include_video_language=en,tr → hem İngilizce hem
        // (varsa) Türkçe fragmanlar gelsin; seçimi MovieDetail.trailerKey yapar.
        guard let url = URL(string:
            "https://api.themoviedb.org/3/movie/\(id)?language=en-US&append_to_response=credits,watch/providers,translations,videos&include_video_language=en,tr")
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
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "include_adult", value: "false")   // yetişkin içeriği ele
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let response: MovieResponse = try await client.fetch(url: url)
        return response.results
    }

    // Filtreli keşif (/discover/movie). Tür/platform/süre/sıralama parametreleri.
    // Başlık/poster kuralı gereği language=en-US (orijinal). Platform seçilirse
    // watch_region app diline göre (TR/US).
    func fetchDiscover(filter: MovieFilter, page: Int = 1) async throws -> [Movie] {
        try await fetchDiscover(params: filter.discoverParams, page: page)
    }

    // Çözülmüş parametrelerle /discover — hem filtre hem refill (odaya kayıtlı filtre) buradan geçer.
    func fetchDiscover(params: DiscoverParams, page: Int = 1) async throws -> [Movie] {
        guard var components = URLComponents(string: "https://api.themoviedb.org/3/discover/movie")
        else { throw APIError.invalidURL }

        var items: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sort_by", value: params.sortBy),
            URLQueryItem(name: "include_adult", value: "false"),
            // Puana göre sıralamada bilinmeyen/az oylu filmler tepeye çıkmasın
            URLQueryItem(name: "vote_count.gte", value: params.sortBy == "vote_average.desc" ? "300" : "50"),
        ]
        if !params.genres.isEmpty {   // | = "veya" (herhangi biri)
            items.append(URLQueryItem(name: "with_genres",
                                      value: params.genres.map(String.init).joined(separator: "|")))
        }
        if !params.providers.isEmpty {
            items.append(URLQueryItem(name: "with_watch_providers",
                                      value: params.providers.map(String.init).joined(separator: "|")))
            items.append(URLQueryItem(name: "watch_region", value: params.region ?? "US"))
        }
        if let mn = params.runtimeMin { items.append(URLQueryItem(name: "with_runtime.gte", value: String(mn))) }
        if let mx = params.runtimeMax { items.append(URLQueryItem(name: "with_runtime.lte", value: String(mx))) }
        if let r  = params.minRating  { items.append(URLQueryItem(name: "vote_average.gte", value: String(r))) }
        components.queryItems = items

        guard let url = components.url else { throw APIError.invalidURL }
        let response: MovieResponse = try await client.fetch(url: url)
        return response.results
    }

    // Ana ekran mod satırı (/discover). Mod tanımındaki tür/süre/puan → parametreler.
    func fetchMood(_ mood: HomeMood, page: Int = 1) async throws -> [Movie] {
        guard var components = URLComponents(string: "https://api.themoviedb.org/3/discover/movie")
        else { throw APIError.invalidURL }

        var items: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sort_by", value: mood.sort.apiValue),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "vote_count.gte", value: mood.sort == .topRated ? "300" : "80"),
        ]
        if !mood.genres.isEmpty {
            items.append(URLQueryItem(name: "with_genres",
                                      value: mood.genres.map(String.init).joined(separator: "|")))
        }
        if let mn = mood.runtimeMin { items.append(URLQueryItem(name: "with_runtime.gte", value: String(mn))) }
        if let mx = mood.runtimeMax { items.append(URLQueryItem(name: "with_runtime.lte", value: String(mx))) }
        if let r  = mood.minRating  { items.append(URLQueryItem(name: "vote_average.gte", value: String(r))) }
        components.queryItems = items

        guard let url = components.url else { throw APIError.invalidURL }
        let response: MovieResponse = try await client.fetch(url: url)
        return response.results
    }
}
