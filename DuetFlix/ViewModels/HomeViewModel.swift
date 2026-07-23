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

// Ana ekran satırı — başlık + filmler (mod satırları için)
struct HomeRow: Identifiable {
    let id: String
    let title: String
    let movies: [Movie]
}

// "Mod / ruh hali" tanımı → TMDB /discover parametrelerine çevrilir.
// Kuru tür yerine "Kısa ve tatlı / Şaheserler / İkiniz için…" gibi çağrışımlı satırlar.
struct HomeMood: Identifiable, Sendable {
    let id: String
    let titleKey: String            // lokalizasyon anahtarı
    var genres: [Int] = []          // OR'lanır
    var runtimeMin: Int? = nil
    var runtimeMax: Int? = nil
    var minRating: Double? = nil    // vote_average.gte
    var sort: MovieSort = .popular
}

// ana thread'de çalışsın, state değiştiğinde ekran değişeceği için main threadde olması lazım
@MainActor
// bu sınıf izlenir, değişince swiftui otomatik değişir
@Observable

// final = bu sınıftan kimse miras almayacak
final class HomeViewModel {
    // dışarıdan okunur ama değiştirilemez
    private(set) var state: HomeState = .loading
    private(set) var movies: [Movie] = []        // popüler filmler (carousel + popüler satırı)
    private(set) var rows: [HomeRow] = []         // mod satırları
    private(set) var isLoadingMore = false        // sonraki sayfa yükleniyor mu

    private var page = 1                           // şu an kaçıncı sayfadayız
    private let service: TMDBService

    init(service: TMDBService = TMDBServiceLive()) {
        self.service = service
    }

    // Sabit mod satırları (çağrışımlı — kuru tür değil)
    private let staticMoods: [HomeMood] = [
        HomeMood(id: "short",        titleKey: "mood.short",        runtimeMax: 90),
        HomeMood(id: "masterpieces", titleKey: "mood.masterpieces", minRating: 7.5, sort: .topRated),
        HomeMood(id: "brainoff",     titleKey: "mood.brainoff",     genres: [35, 28]),      // komedi/aksiyon
        HomeMood(id: "thrill",       titleKey: "mood.thrill",       genres: [53, 27]),      // gerilim/korku
        HomeMood(id: "together",     titleKey: "mood.together",     genres: [10749, 35]),   // romantik/komedi
        HomeMood(id: "family",       titleKey: "mood.family",       genres: [10751, 16]),   // aile/animasyon
        HomeMood(id: "long",         titleKey: "mood.long",         runtimeMin: 150),
    ]

    // Zamana duyarlı satır (güne göre değişir) — ekran canlı hissetsin
    private var timeMood: HomeMood {
        switch Calendar.current.component(.weekday, from: Date()) {   // 1=Paz … 6=Cum, 7=Cmt
        case 6, 7:  return HomeMood(id: "time", titleKey: "mood.friday", genres: [28, 12, 878])   // dolu dizgin
        case 1:     return HomeMood(id: "time", titleKey: "mood.sunday", genres: [35, 10751, 18]) // rahat
        default:    return HomeMood(id: "time", titleKey: "mood.weekday", genres: [35, 18])       // bu akşam: komedi/dram
        }
    }

    private var moods: [HomeMood] { [timeMood] + staticMoods }

    // İlk yükleme: popüler + mod satırları (paralel)
    func loadHome() async {
        state = .loading
        page = 1
        do {
            // 1) Popüler (carousel + popüler satırı) — önce bu gelmeli
            let popular = try await service.fetchPopular(page: 1)
            movies = popular
            prefetchPosters(popular)

            // 2) Mod satırlarını paralel çek (kaynak sırasını koru)
            let service = self.service
            let moods = self.moods
            var byID: [String: [Movie]] = [:]
            await withTaskGroup(of: (String, [Movie]).self) { group in
                for mood in moods {
                    group.addTask {
                        let movies = (try? await service.fetchMood(mood, page: 1)) ?? []
                        return (mood.id, movies)
                    }
                }
                for await (id, movies) in group { byID[id] = movies }
            }
            rows = moods.compactMap { m in
                guard let list = byID[m.id], !list.isEmpty else { return nil }
                return HomeRow(id: m.id, title: L(m.titleKey), movies: list)
            }
            rows.forEach { prefetchPosters($0.movies) }

            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // "Zar at": yüklenen tüm havuzdan rastgele bir film seç
    func surprisePick() -> Movie? {
        (movies + rows.flatMap(\.movies)).randomElement()
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
