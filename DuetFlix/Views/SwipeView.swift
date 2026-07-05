//
//  SwipeView.swift
//  DuetFlix
//
//  Tinder-vari film kaydırma ekranı: sağa = beğen, sola = geç.
//

import SwiftUI
import SwiftData
import Kingfisher

struct SwipeView: View {
    let code: String
    let uid: String

    @State private var viewModel = SwipeViewModel()
    @State private var drag: CGSize = .zero
    @State private var swipeTrigger = 0        // haptik tetikleyici
    @State private var detailMovie: DeckMovie? // detay sheet için
    @State private var showMatches = false     // "Bu gece için" eşleşme listesi sheet'i
    @State private var showEndConfirm = false  // "Oyunu bitir" onayı

    @Environment(\.modelContext) private var context
    @Query private var savedMatches: [SavedMatch]      // kalıcı eşleşmeler (SwiftData)
    @Query private var watchlist: [WatchlistItem]      // izleme listesi (otomatik ekleme için)

    private let threshold: CGFloat = 120

    var body: some View {
        GeometryReader { geo in
            // Karta ekrana göre boyut (her cihazda düzgün)
            let cardW = min(geo.size.width - 56, 360)
            let cardH = min(cardW * 1.42, geo.size.height * 0.60)

            ZStack {
                Color.umbraBackground.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.lg) {
                    header

                    if viewModel.deck.isEmpty {
                        Spacer()
                        ProgressView("Deste yükleniyor…")
                        Spacer()
                    } else if viewModel.isFinished {
                        Spacer()
                        if viewModel.refillError {
                            ErrorView(message: "Yeni filmler yüklenemedi") {
                                Task { await viewModel.retryRefill(code: code) }
                            }
                        } else {
                            finishedView
                        }
                        Spacer()
                    } else {
                        Spacer(minLength: 0)
                        cardStack(width: cardW, height: cardH)
                        Spacer(minLength: 0)
                        actionButtons
                        // Küçük, göze batmayan bilgilendirme
                        Label("Kaydırarak ya da butonlarla beğen veya geç",
                              systemImage: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary.opacity(0.6))
                            .padding(.top, Theme.Spacing.xs)
                    }
                }
                .padding()

                // İkiniz de beğendiniz → kutlama (her iki oyuncuda da açılır)
                if let match = viewModel.newMatch {
                    matchOverlay(match)
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.newMatch?.id)
        .sensoryFeedback(.impact, trigger: swipeTrigger)
        .sensoryFeedback(.success, trigger: viewModel.newMatch?.id)
        .onAppear { viewModel.listen(code: code, uid: uid) }
        .onDisappear { viewModel.stopListening() }
        // Eşleşen filmler değişince (deste yüklenince, yeni eşleşme, çıkarma) kalıcı
        // listeyi (SwiftData) güncelle. matchedMovies idsi tüm bu durumlarda değişir.
        .onChange(of: viewModel.matchedMovies.map(\.id)) { _, _ in syncSavedMatches() }
        // Oyunu bitir → önce özet/onay
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Bitir") { showEndConfirm = true }
                    .tint(.ember)
            }
        }
        .confirmationDialog("Oyunu bitir?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            if !viewModel.matchedMovies.isEmpty {
                Button("Eşleşmeleri gör (\(viewModel.matchedMovies.count))") { showMatches = true }
            }
            Button("Lobiye dön") { viewModel.endGame(code: code) }
            Button("İptal", role: .cancel) {}
        } message: {
            Text(viewModel.matchedMovies.isEmpty
                 ? "Henüz eşleşmeniz yok."
                 : "Bu gece için \(viewModel.matchedMovies.count) eşleşmeniz var.")
        }
        // Filmin detayını (özet, oyuncular, nerede izlenir) sheet olarak göster
        .sheet(item: $detailMovie) { movie in
            DetailView(movieID: movie.id, showWatchlistButton: false)   // Duo kalp yok
                .modelContainer(AppDatabase.shared)   // sheete SwiftData deposunu ver
        }
        // Eşleşen filmler listesi ("Bu gece için seçilenler")
        .sheet(isPresented: $showMatches) {
            MatchesView(viewModel: viewModel, code: code)
                .modelContainer(AppDatabase.shared)   // içindeki DetailView için
        }
    }

    // Canlı eşleşmeleri SwiftDataya yansıtma yeni eşleşme → kaydet, çıkarılan → sil.
    // Oda kapanınca matchedMovies boşalır ama kayıtlar silinmez.
    private func syncSavedMatches() {
        let saved = Set(savedMatches.map(\.movieID))
        let inWatchlist = Set(watchlist.map(\.movieID))
        // Ekle: eşleşmiş, çıkarılmamış, henüz kaydedilmemiş
        for movie in viewModel.matchedMovies where !saved.contains(movie.id) {
            context.insert(SavedMatch(movieID: movie.id, title: movie.title,
                                      posterPath: movie.posterPath, voteAverage: movie.voteAverage,
                                      roomCode: code, partners: viewModel.memberNames))
            // Eşleşen filmi kişisel izleme listesine de ekle (zaten yoksa)
            // böylece elle kalple eklemeye gerek kalmaz, DetailViewde kalp dolu gelir.
            if !inWatchlist.contains(movie.id) {
                context.insert(WatchlistItem(movieID: movie.id, title: movie.title,
                                             posterPath: movie.posterPath, voteAverage: movie.voteAverage))
            }
        }
        // Sil kayıtlı olup artık listeden çıkarılmış (reddedilmiş) olanlar
        for item in savedMatches where viewModel.rejectedIDs.contains(item.movieID) {
            context.delete(item)
        }
    }


    // beğeni sayısı + kaçıncı film ör 23/40
    private var header: some View {
        HStack {
            Text("\(min(viewModel.currentIndex + 1, viewModel.deck.count)) / \(viewModel.deck.count)")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            Spacer()

            // Eşleşme rozeti — yalnızca en az bir eşleşme varken görünür
            if !viewModel.matchedMovies.isEmpty {
                Button { showMatches = true } label: {
                    Label("\(viewModel.matchedMovies.count)", systemImage: "sparkles")
                        .font(.subheadline.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 6)
                        .background(Color.ember, in: Capsule())
                }
                .transition(.scale.combined(with: .opacity))
            }

            Label("\(viewModel.likeCount)", systemImage: "heart.fill")
                .font(.subheadline.bold())
                .foregroundStyle(Color.ember)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.matchedMovies.count)
    }

    private func cardStack(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(visibleCards.reversed(), id: \.movie.id) { item in
                // alt kartlar tam gizli kalırlar
                // Sıra gelince withAnimation ile 1.0'a büyüyüp yerine oturur.
                let scale = 1 - CGFloat(item.depth) * 0.08
                cardView(item.movie, isTop: item.depth == 0, width: width, height: height)
                    .scaleEffect(scale)
                    .offset(y: CGFloat(item.depth) * 10)
                    .offset(item.depth == 0 ? drag : .zero)
                    .rotationEffect(.degrees(item.depth == 0 ? Double(drag.width) / 18 : 0))
                    .zIndex(Double(-item.depth))        // üst kart daima en önde
                    .gesture(item.depth == 0 ? dragGesture : nil)
            }
        }
    }

    private var visibleCards: [(movie: DeckMovie, depth: Int)] {
        let start = viewModel.currentIndex
        let end = min(start + 3, viewModel.deck.count)
        guard start < end else { return [] }
        return (start..<end).map { (viewModel.deck[$0], $0 - start) }
    }

    private func cardView(_ movie: DeckMovie, isTop: Bool, width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            KFImage(movie.posterURL)
                .placeholder { Color.umbraSurface }
                .resizable()
                .aspectRatio(contentMode: .fill)

            // Alttan karartma + başlık + puan (yalnızca en üstteki kartta;
            if isTop {
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    Text(movie.title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundStyle(Color.ratingStar)
                        Text(String(format: "%.1f", movie.voteAverage)).foregroundStyle(.white)
                    }
                    .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .background(
                    LinearGradient(colors: [.black.opacity(0.9), .clear],
                                   startPoint: .bottom, endPoint: .center)
                )
            }

            // Sürükleme damgaları
            if isTop {
                HStack {
                    stamp("BEĞEN", color: .green, opacity: Double(max(0, drag.width) / threshold))
                    Spacer()
                    stamp("GEÇ", color: .red, opacity: Double(max(0, -drag.width) / threshold))
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.5), radius: 12, y: 8)
    }

    private func stamp(_ text: String, color: Color, opacity: Double) -> some View {
        Text(text)
            .font(.system(size: 30, weight: .heavy))
            .foregroundStyle(color)
            .padding(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 4))
            .rotationEffect(.degrees(-14))
            .opacity(min(opacity, 1))
    }

    // Alt aksiyon butonları (geç · detay · beğen)

    private var actionButtons: some View {
        HStack(spacing: 32) {
            circleButton(icon: "xmark", color: .red) { performSwipe(like: false) }

            // Detay (info) — mevcut kartın detayını sheet aç
            Button {
                detailMovie = viewModel.currentMovie
            } label: {
                Image(systemName: "info")
                    .font(.title2.bold())
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 52, height: 52)
                    .background(Color.umbraSurface, in: Circle())
                    .overlay(Circle().stroke(Color.textSecondary.opacity(0.3), lineWidth: 1))
            }

            circleButton(icon: "heart.fill", color: .ember) { performSwipe(like: true) }
        }
        .padding(.top, Theme.Spacing.sm)
    }

    private func circleButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title.bold())
                .foregroundStyle(color)
                .frame(width: 64, height: 64)
                .background(Color.umbraSurface, in: Circle())
                .overlay(Circle().stroke(color.opacity(0.4), lineWidth: 1))
        }
    }

    // Deste bitti durumu

    private var finishedView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "hourglass")
                .font(.largeTitle)
                .foregroundStyle(Color.ember)
            Text("Tüm filmleri değerlendirdin!")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            Text("Yeni filmler yükleniyor…")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            ProgressView()
        }
    }

    // Eşleşme kutlaması

    private func matchOverlay(_ movie: DeckMovie) -> some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Text("EŞLEŞTİNİZ!")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(Color.ember)
                    .shadow(color: Color.ember.opacity(0.5), radius: 12)

                KFImage(movie.posterURL)
                    .placeholder { Color.umbraSurface }
                    .resizable()
                    .aspectRatio(2 / 3, contentMode: .fit)
                    .frame(maxWidth: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.ember.opacity(0.4), radius: 20)

                Text(movie.title)
                    .font(.title3.bold())
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("İkiniz de bu filmi beğendiniz — bu akşamki film bu olabilir 🍿")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: Theme.Spacing.sm) {
                    Button {
                        viewModel.clearMatch()
                        detailMovie = movie
                    } label: {
                        Text("Detayları gör")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ember, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.black)
                    }

                    Button("Kaydırmaya devam") { viewModel.clearMatch() }
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, Theme.Spacing.xs)
                }
                .padding(.horizontal, Theme.Spacing.xl)
            }
            .padding()
        }
    }

    // Gesture & swipe

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { drag = $0.translation }
            .onEnded { value in
                if value.translation.width > threshold {
                    performSwipe(like: true)
                } else if value.translation.width < -threshold {
                    performSwipe(like: false)
                } else {
                    withAnimation(.spring()) { drag = .zero }
                }
            }
    }

    private func performSwipe(like: Bool) {
        swipeTrigger += 1                  // haptik
        // 1) Üstteki kart ekrandan uçsun
        withAnimation(.easeOut(duration: 0.25)) {
            drag = CGSize(width: like ? 700 : -700, height: drag.height)
        }
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            // 2) Konumu ilerlet + drag sıfırla — arkadaki kartın büyümesi yumuşak olsun
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                viewModel.swipe(like: like, code: code)
                drag = .zero
            }
        }
    }
}
