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
                .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }

            SearchView()
                .tabItem { Label("Keşfet", systemImage: "magnifyingglass") }

            WatchlistView()
                .tabItem { Label("İzleme Listesi", systemImage: "bookmark.fill") }

            ProfileView(onChangeMode: onChangeMode)
                .tabItem { Label("Profil", systemImage: "person.fill") }
        }
        .tint(.ember)
    }
}

#Preview {
    MainTabView(onChangeMode: {})
        .preferredColorScheme(.dark)
}
