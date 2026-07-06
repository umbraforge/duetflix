//
//  MovieDetail.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import Foundation


struct Genre: Codable, Identifiable {
    let id: Int
    let name: String

    // TMDB tür ID'leri sabit → Türkçe karşılıkları. TR seçiliyse Türkçe, yoksa TMDnin İngilizce adı.
    private static let turkish: [Int: String] = [
        28: "Aksiyon", 12: "Macera", 16: "Animasyon", 35: "Komedi", 80: "Suç",
        99: "Belgesel", 18: "Dram", 10751: "Aile", 14: "Fantastik", 36: "Tarih",
        27: "Korku", 10402: "Müzik", 9648: "Gizem", 10749: "Romantik",
        878: "Bilim Kurgu", 10770: "TV Filmi", 53: "Gerilim", 10752: "Savaş", 37: "Western"
    ]

    var localizedName: String {
        if LocalizationManager.shared.language == .tr, let tr = Genre.turkish[id] { return tr }
        return name
    }
}

struct MovieDetail: Codable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let releaseDate: String
    let runtime: Int?
    let genres : [Genre]
    let credits: Credits
    let watchProviders: WatchProviders?
    let translations: Translations?   // başlık/poster orijinal kalır; sadece açıklamayı buradan çeviririz

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
        case runtime
        case genres
        case credits
        case watchProviders = "watch/providers"
        case translations
    }
}

// TMDB append_to_response=translations yapısı
struct Translations: Codable {
    let translations: [Translation]
}
struct Translation: Codable {
    let iso639_1: String
    let data: TranslationData
    enum CodingKeys: String, CodingKey {
        case iso639_1 = "iso_639_1"
        case data
    }
}
struct TranslationData: Codable {
    let overview: String?
}

extension MovieDetail {
    // Açıklama: TR seçiliyse Türkçe, yoksa orijinal
    var localizedOverview: String {
        if LocalizationManager.shared.language == .tr,
           let turkish = translations?.translations.first(where: { $0.iso639_1 == "tr" })?.data.overview,
           !turkish.isEmpty {
            return turkish
        }
        return overview
    }
}

extension MovieDetail {
    var posterURL: URL? {
        guard let posterPath else {return nil} // posteri yoksa nil
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") // poster'in url'si
    }
    var backdropURL: URL? {
        guard let backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(backdropPath)")   // daha geniş boyut
    }
}

extension CountryProviders {
    /// Bu bölgedeki tüm sağlayıcılar (abone + kirala + satın al), tekrarsız.
    var allProviders: [Provider] {
        let combined = (flatrate ?? []) + (rent ?? []) + (buy ?? [])
        var seen = Set<Int>()
        return combined.filter { seen.insert($0.id).inserted }   // aynı sağlayıcıyı 1 kez al
    }
}

extension WatchProviders {
    /// Tercih sırasına göre ilk dolu bölgenin sağlayıcılarını verir.
    var preferredProviders: [Provider] {
        let regions = ["TR", "US", "GB", "DE"]
        for region in regions {
            if let country = results[region], !country.allProviders.isEmpty {
                return country.allProviders
            }
        }
        // hiçbiri yoksa: eldeki herhangi bir dolu bölge
        return results.values.first(where: { !$0.allProviders.isEmpty })?.allProviders ?? []
    }
}

struct Credits: Codable {
    let cast: [CastMember]
}

struct CastMember: Codable, Identifiable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }
}

struct WatchProviders: Codable {
    let results: [String: CountryProviders]   // "TR", "US" ... → o ülkenin sağlayıcıları
}

struct CountryProviders: Codable {
    let flatrate: [Provider]?     // abonelikle izle (Netflix vb.)
    let rent: [Provider]?         // kirala
    let buy: [Provider]?          // satın al
}

struct Provider: Codable, Identifiable {
    let providerId: Int
    let providerName: String
    let logoPath: String?

    var id: Int { providerId }

    enum CodingKeys: String, CodingKey {
        case providerId = "provider_id"
        case providerName = "provider_name"
        case logoPath = "logo_path"
    }
}
