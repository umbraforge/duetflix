//
//  DuetFlixApp.swift
//  DuetFlix
//
//  Created by Batu on 30.06.2026.
//

import SwiftUI
import SwiftData
import FirebaseCore


@main // uygulama burdan başlar
struct DuetFlixApp: App {
    init() {
        FirebaseApp.configure() // uygulama açılınca firebase'i başlat (GoogleService infoyu okur bağlanır)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(AppDatabase.shared) // watchlist + kalıcı eşleşmeler
    }
}

enum AppDatabase {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: WatchlistItem.self, SavedMatch.self)
        } catch {
            fatalError("SwiftData container oluşturulamadı: \(error)")
        }
    }()
}
