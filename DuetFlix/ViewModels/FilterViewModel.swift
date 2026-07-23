//
//  FilterViewModel.swift
//  DuetFlix
//
//  Keşfet filtresi durumu + sonuçlar + "2 bedava kullanım sonra Plus" kapısı.
//

import Foundation

@MainActor
@Observable
final class FilterViewModel {
    enum State { case idle, loading, loaded, empty, error }

    var filter = MovieFilter()
    private(set) var results: [Movie] = []
    private(set) var state: State = .idle
    var showPaywall = false

    private let tmdb: TMDBService = TMDBServiceLive()

    // Plus olmayan kullanıcı için toplam bedava filtreleme hakkı
    static let freeLimit = 2
    private let usedKey = "filter_free_uses_used"
    var freeUsesLeft: Int {
        max(0, Self.freeLimit - UserDefaults.standard.integer(forKey: usedKey))
    }

    // Filtreyi uygula. Plus değilse ve hak bittiyse paywall aç; başarılı ve Plus değilse hakkı düş.
    // (Başarısız istek hak yakmaz.)
    func apply(isPlus: Bool) async {
        // Boş filtre (yalnızca popüler) bedava hak yakmaz — sadece gerçek bir filtre sayılır.
        let usesFeature = !filter.isDefault
        if usesFeature && !isPlus && freeUsesLeft == 0 {
            showPaywall = true
            return
        }
        state = .loading
        do {
            let movies = try await tmdb.fetchDiscover(filter: filter, page: 1)
            results = movies
            state = movies.isEmpty ? .empty : .loaded
            if usesFeature && !isPlus {
                let used = UserDefaults.standard.integer(forKey: usedKey)
                UserDefaults.standard.set(used + 1, forKey: usedKey)
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
        filter.runtime = (filter.runtime == range) ? nil : range
    }

    func reset() {
        filter = MovieFilter()
        results = []
        state = .idle
    }
}
