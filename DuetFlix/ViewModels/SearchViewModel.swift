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

    private let service: TMDBService
    private var searchTask: Task<Void, Never>?   // çalışan aramayı iptal edebilmek için

    init(service: TMDBService = TMDBServiceLive()) {
        self.service = service
    }

    private func scheduleSearch() {
        // Önceki bekleyen aramayı iptal et (kullanıcı yazmaya devam ediyor)
        searchTask?.cancel()

        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            results = []
            return
        }

        searchTask = Task {
            // 300ms bekle — kullanıcı yazmayı bitirsin
            try? await Task.sleep(for: .milliseconds(300))
            if Task.isCancelled { return }   // bu arada yeni harf geldiyse çık

            isSearching = true
            do {
                results = try await service.fetchSearch(query: text)
            } catch {
                results = []
            }
            isSearching = false
        }
    }
}
