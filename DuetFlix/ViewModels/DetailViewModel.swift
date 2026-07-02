//
//  DetailViewModel.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import Foundation
import Observation


enum DetailState {
    case loading
    case loaded(MovieDetail)     // tek detay taşır
    case error(String)
}

@MainActor
@Observable
final class DetailViewModel {
    private(set) var state: DetailState = .loading
    private let service: TMDBService
    private let movieID: Int          // hangi filmin detayı

    init(movieID: Int, service: TMDBService = TMDBServiceLive()) {
        self.movieID = movieID
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            let movie = try await service.fetchDetail(id: movieID)
            state = .loaded(movie)
        } catch {
            state = .error(error.localizedDescription)
        }
        
    }
}
