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
            HomeView(onChangeMode: onChangeMode)
                .tabItem { Label(L("tab.home"), systemImage: "house.fill") }

            SearchView()
                .tabItem { Label(L("tab.discover"), systemImage: "magnifyingglass") }

            WatchlistView()
                .tabItem { Label(L("tab.watchlist"), systemImage: "bookmark.fill") }

            ProfileView()
                .tabItem { Label(L("tab.profile"), systemImage: "person.fill") }
        }
        .tint(.ember)
    }
}

#Preview {
    MainTabView(onChangeMode: {})
        .preferredColorScheme(.dark)
}
