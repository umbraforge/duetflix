//
//  FilterViewModel.swift
//  DuetFlix
//
//  Keşfet filtresi durumu + sonuçlar + "hak bitince ödüllü reklam" kapısı.
//

import Foundation

@MainActor
@Observable
final class FilterViewModel {
    enum State { case idle, loading, loaded, empty, error }

    var filter = MovieFilter()
    private(set) var results: [Movie] = []
    private(set) var state: State = .idle
    var showReward = false   // hak bitti → view ödüllü reklam ekranını açsın

    private let tmdb: TMDBService = TMDBServiceLive()

    // Filtreyi uygula. Hak yoksa ödül ekranını aç; başarılı olursa bir hak harca.
    // Hak YAKMAYAN durumlar: boş filtre (yalnızca popüler), başarısız istek ve
    // bu açılışta zaten ödenmiş aynı filtrenin tekrarı.
    func apply(credits: FilterCredits) async {
        let usesFeature = !filter.isDefault
        let alreadyPaid = credits.hasPaid(for: filter)
        let mustPay = usesFeature && !alreadyPaid

        if mustPay && credits.isEmpty {
            showReward = true
            return
        }
        state = .loading
        do {
            let movies = try await tmdb.fetchDiscover(filter: filter, page: 1)
            results = movies
            state = movies.isEmpty ? .empty : .loaded
            if mustPay {
                credits.spend()
                credits.recordPaid(filter)
            }
        } catch {
            state = .error
        }
    }

    // Tür / platform seç-kaldır (çoklu). Süre / sıralama tekli.
    func toggleGenre(_ id: Int) {
        if filter.genres.contains(id) { filter.genres.remove(id) } else { filter.genres.insert(id) }
    }
    func toggleProvider(_ id: Int) {
        if filter.providers.contains(id) { filter.providers.remove(id) } else { filter.providers.insert(id) }
    }
    func toggleRuntime(_ range: RuntimeRange) {
        if filter.runtimes.contains(range) { filter.runtimes.remove(range) } else { filter.runtimes.insert(range) }
    }
    func toggleRating(_ rating: MinRating) {   // tekli: aynısına basınca kapat
        filter.minRating = (filter.minRating == rating) ? nil : rating
    }

    func reset() {
        filter = MovieFilter()
        results = []
        state = .idle
    }
}
