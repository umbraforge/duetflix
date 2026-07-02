//
//  MainTabView.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI

struct MainTabView: View {
    let onChangeMode: () -> Void 

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            DiscoverView()
                .tabItem { Label("Discover", systemImage: "magnifyingglass") }

            WatchlistView()
                .tabItem { Label("Watchlist", systemImage: "bookmark.fill") }

            ProfileView(onChangeMode: onChangeMode)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(.ember)
    }
}

#Preview {
    MainTabView(onChangeMode: {})
        .preferredColorScheme(.dark)
}
