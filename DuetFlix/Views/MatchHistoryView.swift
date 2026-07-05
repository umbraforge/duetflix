//
//  MatchHistoryView.swift
//  DuetFlix
//
//  Geçmiş eşleşmeler (kalıcı, SwiftData). Oturumlara (oda) göre gruplanır;
//  her grup başlığında lobideki isimler ve tarih görünür. Duo ekranından açılır.
//

import SwiftUI
import SwiftData

struct MatchHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedMatch.matchedAt, order: .reverse) private var matches: [SavedMatch]

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    // Aynı oturumdaki (oda kodu) eşleşmeleri grupla, en yeni oturum en üstte.
    private var sessions: [(code: String, items: [SavedMatch])] {
        var groups: [String: [SavedMatch]] = [:]
        for match in matches {
            groups[match.roomCode, default: []].append(match)
        }
        var result: [(code: String, items: [SavedMatch])] = []
        for (code, items) in groups {
            let sorted = items.sorted { $0.matchedAt > $1.matchedAt }
            result.append((code: code, items: sorted))
        }
        result.sort { a, b in
            let aDate = a.items.first?.matchedAt ?? Date.distantPast
            let bDate = b.items.first?.matchedAt ?? Date.distantPast
            return aDate > bDate
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()

                if matches.isEmpty {
                    ContentUnavailableView("Henüz eşleşme yok",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Bir Duo oyununda eşleştiğiniz filmler burada birikir"))
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                            ForEach(sessions, id: \.code) { session in
                                sessionSection(session.items)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Geçmiş Eşleşmeler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }.tint(.ember)
                }
            }
        }
        .tint(.ember)
    }

    // Bir oturum  kimler + tarih başlığı + poster grid'i
    private func sessionSection(_ session: [SavedMatch]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(Color.ember)
                Text(partnersLabel(session))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(dateLabel(session))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(session) { match in
                    NavigationLink {
                        DetailView(movieID: match.movieID, showWatchlistButton: false)
                    } label: {
                        PosterTile(url: match.posterURL, title: match.title)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            context.delete(match)
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private func partnersLabel(_ session: [SavedMatch]) -> String {
        let names = session.first?.partners ?? []
        return names.isEmpty ? "Duo oyunu" : names.joined(separator: " & ")
    }

    private func dateLabel(_ session: [SavedMatch]) -> String {
        guard let date = session.first?.matchedAt else { return "" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
