//
//  HomeViewModel.swift
//  DuetFlix
//
//  Created by Batu on 1.07.2026.
//

import Foundation
import Observation
import Kingfisher

enum HomeState  {
    case loading
    case loaded          // başarılı — filmler ayrı `movies` dizisinde
    case error(String)   // hata, mesajı taşır
}

// ana thread'de çalışsın, state değiştiğinde ekran değişeceği için main threadde olması lazım
@MainActor
// bu sınıf izlenir, değişince swiftui otomatik değişir
@Observable

// final = bu sınıftan kimse miras almayacak
final class HomeViewModel {
    // dışarıdan okunur ama değiştirilemez
    private(set) var state: HomeState = .loading
    private(set) var movies: [Movie] = []        // filmlerin tek doğru kaynağı
    private(set) var isLoadingMore = false        // sonraki sayfa yükleniyor mu

    private var page = 1                           // şu an kaçıncı sayfadayız
    private let service: TMDBService

    init(service: TMDBService = TMDBServiceLive()) {
        self.service = service
    }

    // İlk yükleme (1. sayfa)
    func loadPopular() async {
        state = .loading
        page = 1
        do {
            movies = try await service.fetchPopular(page: page)
            prefetchPosters(movies)
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // Sonraki sayfayı yükle ve mevcut listeye ekle
    func loadMore() async {
        guard !isLoadingMore else { return }       // zaten yükleniyorsa tekrar başlatma
        isLoadingMore = true
        do {
            let next = try await service.fetchPopular(page: page + 1)
            page += 1
            // Aynı filmi iki kez eklememek için id'ye göre süz
            let existingIDs = Set(movies.map(\.id))
            let fresh = next.filter { !existingIDs.contains($0.id) }
            prefetchPosters(fresh)                      // yeni posterleri önden indir
            movies.append(contentsOf: fresh)
        } catch {
            // sessizce geç — sonraki kaydırmada tekrar denenir
        }
        isLoadingMore = false
    }

    // Posterleri arka planda önceden indir → kart görününce resim hazır (akıcılık)
    private func prefetchPosters(_ movies: [Movie]) {
        let urls = movies.compactMap(\.posterURL)
        ImagePrefetcher(urls: urls).start()
    }
}
