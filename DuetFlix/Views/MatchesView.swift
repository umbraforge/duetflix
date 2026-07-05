//
//  MatchesView.swift
//  DuetFlix
//
//  "Bu gece için seçilenler" — OYUN İÇİ canlı eşleşme listesi (odadan okunur).
//  Swipe ekranındaki rozetten sheet olarak açılır. Partnerin çıkarması anında yansır.
//  Kalıcı geçmiş için ayrı ekran: MatchHistoryView (Duo > Geçmiş Eşleşmeler).
//

import SwiftUI
import Kingfisher

struct MatchesView: View {
    let viewModel: SwipeViewModel
    let code: String
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    // @Observable viewModelden canlı okunur; çıkarınca liste anında güncellenir
    private var movies: [DeckMovie] { viewModel.matchedMovies }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()

                if movies.isEmpty {
                    ContentUnavailableView("Henüz eşleşme yok",
                        systemImage: "sparkles",
                        description: Text("İkinizin de beğendiği filmler burada toplanır"))
                } else {
                    ScrollView {
                        Text("İkinizin de beğendiği \(movies.count) film")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, Theme.Spacing.xs)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(movies) { movie in
                                NavigationLink {
                                    DetailView(movieID: movie.id, showWatchlistButton: false)
                                } label: {
                                    PosterTile(url: movie.posterURL, title: movie.title)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.removeMatch(movieID: movie.id, code: code)
                                    } label: {
                                        Label("Listeden çıkar", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: movies.count)

                        // Küçük bilgilendirme
                        Label("Bir filmi çıkarmak için üzerine basılı tut",
                              systemImage: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary.opacity(0.6))
                            .padding(.bottom, Theme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Bu gece için")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .tint(.ember)
                }
            }
        }
        .tint(.ember)
    }
}
