//
//  HomeViewModel.swift
//  DuetFlix
//
//  Created by Batu on 1.07.2026.
//

import Foundation
import Observation

enum HomeState  {
    case loading
    case loaded([Movie]) // başarılı, filmleri taşır
    case error(String) // hata, mesajı taşır
}

// ana thread'de çalışsın, state değiştiğinde ekran değişeceği için main threadde olması lazım
@MainActor
// bu sınıf izlenir, değişince swiftui otomatik değişir
@Observable

// final = bu sınıftan kimse miras almayacak
final class HomeViewModel {
    // dışarıdan okunur ama değiştirilemez
    private(set) var state: HomeState = .loading
    private let service: TMDBService
    
    init(service: TMDBService = TMDBServiceLive()) {
        self.service = service
    }
    
    func loadPopular() async {
        state = .loading // başlangıçta loading
        do {
            let movies = try await service.fetchPopular()
            state = .loaded(movies) // başarılı, movie'leri taşı
        } catch { // hatalı, hata mesajını taşı
            state = .error(error.localizedDescription)
        }
    }
}
