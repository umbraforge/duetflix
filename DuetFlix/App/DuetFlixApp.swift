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
        .modelContainer(for: WatchlistItem.self) // watchlist için veritabanı
    }
}
