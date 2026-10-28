//
//  MovieFilter.swift
//  DuetFlix
//
//  Keşfet filtresi: tür + platform + süre aralığı + puan + sıralama.
//  TMDB /discover/movie parametrelerine çevrilir.
//

import Foundation

// Süre aralıkları (dakika) — kullanıcının istediği bantlar
enum RuntimeRange: String, CaseIterable, Identifiable {
    case r30_60, r60_90, r90_120, r120_150, r150_180, r180_210
    var id: String { rawValue }
    var bounds: (min: Int, max: Int) {
        switch self {
        case .r30_60:   return (30, 60)
        case .r60_90:   return (60, 90)
        case .r90_120:  return (90, 120)
        case .r120_150: return (120, 150)
        case .r150_180: return (150, 180)
        case .r180_210: return (180, 210)
        }
    }
    var label: String { "\(bounds.min)-\(bounds.max) \(L("detail.min"))" }
}

// Minimum puan eşiği (vote_average.gte). 6+ / 7+ / 8+
enum MinRating: Int, CaseIterable, Identifiable {
    case r6 = 6, r7 = 7, r8 = 8
    var id: Int { rawValue }
    var value: Double { Double(rawValue) }
    var label: String { "\(rawValue)+" }
}

// Sıralama seçenekleri
enum MovieSort: String, CaseIterable, Identifiable {
    case popular    // popularity.desc
    case topRated   // vote_average.desc (+ vote_count eşiği) — "puana göre" (TMDB puanı)
    case newest     // primary_release_date.desc
    var id: String { rawValue }
    var apiValue: String {
        switch self {
        case .popular:  return "popularity.desc"
        case .topRated: return "vote_average.desc"
        case .newest:   return "primary_release_date.desc"
        }
    }
    var labelKey: String {
        switch self {
        case .popular:  return "filter.sort.popular"
        case .topRated: return "filter.sort.top_rated"
        case .newest:   return "filter.sort.newest"
        }
    }
}

// Filtrelenebilir tür (TMDB tür id'si + isim). MovieDetail'deki Genre id'leriyle aynı.
struct FilterGenre: Identifiable {
    let id: Int
    let tr: String
    let en: String
    var name: String { LocalizationManager.shared.language == .tr ? tr : en }

    static let all: [FilterGenre] = [
        .init(id: 28,    tr: "Aksiyon",     en: "Action"),
        .init(id: 12,    tr: "Macera",      en: "Adventure"),
        .init(id: 16,    tr: "Animasyon",   en: "Animation"),
        .init(id: 35,    tr: "Komedi",      en: "Comedy"),
        .init(id: 80,    tr: "Suç",         en: "Crime"),
        .init(id: 99,    tr: "Belgesel",    en: "Documentary"),
        .init(id: 18,    tr: "Dram",        en: "Drama"),
        .init(id: 10751, tr: "Aile",        en: "Family"),
        .init(id: 14,    tr: "Fantastik",   en: "Fantasy"),
        .init(id: 27,    tr: "Korku",       en: "Horror"),
        .init(id: 9648,  tr: "Gizem",       en: "Mystery"),
        .init(id: 10749, tr: "Romantik",    en: "Romance"),
        .init(id: 878,   tr: "Bilim Kurgu", en: "Sci-Fi"),
        .init(id: 53,    tr: "Gerilim",     en: "Thriller"),
        .init(id: 10752, tr: "Savaş",       en: "War"),
        .init(id: 37,    tr: "Western",     en: "Western"),
    ]
}

// Streaming platformu (TMDB provider id). watch_region ile birlikte kullanılır.
struct FilterProvider: Identifiable {
    let id: Int
    let name: String

    static let all: [FilterProvider] = [
        .init(id: 8,   name: "Netflix"),
        .init(id: 119, name: "Prime Video"),
        .init(id: 337, name: "Disney+"),
        .init(id: 350, name: "Apple TV+"),
        .init(id: 11,  name: "MUBI"),
        .init(id: 341, name: "BluTV"),
    ]
}

// Aktif filtre durumu
// Hashable: "bu filtre için zaten ödendi mi" kontrolü için (bkz. FilterCredits)
struct MovieFilter: Hashable {
    var genres: Set<Int> = []
    var providers: Set<Int> = []
    var runtimes: Set<RuntimeRange> = []   // birden fazla süre aralığı seçilebilir
    var minRating: MinRating? = nil        // minimum puan
    var sort: MovieSort = .popular

    // Hiçbir şey seçilmemiş mi? (varsayılan popüler sıralama sayılmaz)
    var isDefault: Bool {
        genres.isEmpty && providers.isEmpty && runtimes.isEmpty && minRating == nil && sort == .popular
    }
}

// Çözülmüş /discover parametreleri — Firestore'a (odaya) yazılıp refill'de yeniden
// kullanılabilir (deste bitince aynı filtreyle devam etsin). Bölge deste kurulurken
// (host tarafında) sabitlenir ki refill'i kim tetiklerse tetiklesin tutarlı kalsın.
struct DiscoverParams: Codable, Sendable {
    var genres: [Int] = []
    var providers: [Int] = []
    var region: String? = nil
    var runtimeMin: Int? = nil
    var runtimeMax: Int? = nil
    var minRating: Double? = nil
    var sortBy: String = "popularity.desc"
}

extension MovieFilter {
    // Bu filtreyi çözülmüş /discover parametrelerine çevir.
    var discoverParams: DiscoverParams {
        var p = DiscoverParams()
        p.genres = Array(genres)
        p.providers = Array(providers)
        if !providers.isEmpty {
            p.region = LocalizationManager.shared.language == .tr ? "TR" : "US"
        }
        if !runtimes.isEmpty {
            p.runtimeMin = runtimes.map(\.bounds.min).min()
            p.runtimeMax = runtimes.map(\.bounds.max).max()
        }
        p.minRating = minRating?.value
        p.sortBy = sort.apiValue
        return p
    }
}
