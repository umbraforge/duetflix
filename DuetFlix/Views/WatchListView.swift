//
//  WatchListView.swift
//  DuetFlix
//
//  Created by Batu on 3.07.2026.
//

import SwiftUI

import SwiftUI
import SwiftData
import Kingfisher

struct WatchlistView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WatchlistItem.addedAt, order: .reverse) private var items: [WatchlistItem]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()

                if items.isEmpty {
                    // Boş durum
                    ContentUnavailableView("Listen boş",
                        systemImage: "bookmark",
                        description: Text("Beğendiğin filmleri ❤️ ile buraya ekle"))
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                            ForEach(items) { item in
                                NavigationLink {
                                    DetailView(movieID: item.movieID)
                                } label: {
                                    KFImage(item.posterURL)
                                        .placeholder { Color.umbraSurface }
                                        .resizable()
                                        .aspectRatio(2/3, contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        context.delete(item)
                                    } label: {
                                        Label("Listeden çıkar", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("İzleme Listesi")
        }
        .tint(.ember)
    }
}

#Preview {
    WatchlistView()
}
