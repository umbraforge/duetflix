//
//  SearchViewModel.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import Foundation

@MainActor
@Observable
final class SearchViewModel {
    var query: String = "" {
        didSet { scheduleSearch() }      // query her değişince zamanlayıcıyı kur
    }
    private(set) var results: [Movie] = []
    private(set) var isSearching = false
    private(set) var didFail = false             // ağ hatası oldu mu (sonuç yok'tan ayırmak için)

    private let service: TMDBService
    private var searchTask: Task<Void, Never>?   // çalışan aramayı iptal edebilmek için

    // Aynı sorguyu tekrar dene (ErrorView'in "Tekrar dene" butonu için)
    func retry() { scheduleSearch() }

    init(service: TMDBService = TMDBServiceLive()) {
        self.service = service
    }

    private func scheduleSearch() {
        // Önceki bekleyen aramayı iptal et (kullanıcı yazmaya devam ediyor)
        searchTask?.cancel()

        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            results = []
            didFail = false
            return
        }

        searchTask = Task {
            // 300ms bekle — kullanıcı yazmayı bitirsin
            try? await Task.sleep(for: .milliseconds(300))
            if Task.isCancelled { return }   // bu arada yeni harf geldiyse çık

            isSearching = true
            didFail = false
            do {
                results = try await service.fetchSearch(query: text)
            } catch {
                results = []
                didFail = true               // "sonuç yok" değil, ağ hatası
            }
            isSearching = false
        }
    }
}
