//
//  DuetFlixApp.swift
//  DuetFlix
//
//  Created by Batu on 30.06.2026.
//

import SwiftUI
import SwiftData

@main // uygulama burdan başlar
struct DuetFlixApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: WatchlistItem.self) // watchlist için veritabanı
    }
}
