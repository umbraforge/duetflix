//
//  DetailView.swift
//  DuetFlix
//
//  Created by Batu on 2.07.2026.
//

import SwiftUI
import Kingfisher

struct DetailView: View {
    let movieID: Int
    @State private var viewModel: DetailViewModel

    init(movieID: Int) {
        self.movieID = movieID
        _viewModel = State(initialValue: DetailViewModel(movieID: movieID))
    }
    var body: some View {
        ZStack {
            Color.umbraBackground.ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                ProgressView()
            case .loaded(let movieDetail):
                content(movieDetail)
            case .error(let message):
                ErrorView(message: message) {
                    Task { await viewModel.load() }
                }
            }
        }
        .task { await viewModel.load() }
    }
    
    @ViewBuilder
    private func content(_ detail: MovieDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header — geniş backdrop görseli
                KFImage(detail.backdropURL)
                    .placeholder { Color.umbraSurface }
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fit)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(detail.title)
                        .font(.title.bold())
                        .foregroundStyle(Color.textPrimary)

                    // yıl, süre,  puan
                    HStack(spacing: 8) {
                        Text(detail.releaseDate.prefix(4))     // "2024-02-27" → "2024"
                        if let runtime = detail.runtime {
                            Text("• \(runtime) dk")
                        }
                        Image(systemName: "star.fill").foregroundStyle(Color.ratingStar)
                        Text(String(format: "%.1f", detail.voteAverage))
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)

                    // Tür pill'leri
                    HStack(spacing: 8) {
                        ForEach(detail.genres) { genre in
                            Text(genre.name)
                                .font(.caption.bold())
                                .foregroundStyle(Color.ember)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.ember.opacity(0.15), in: Capsule())
                        }
                    }

                    // Açıklama
                    Text(detail.overview)
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                    
                    // Nerede izlenir
                    let providers = detail.watchProviders?.preferredProviders ?? []
                    if !providers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nerede izlenir")
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(providers) { provider in
                                        KFImage(provider.logoURL)
                                            .placeholder { Color.umbraSurface }
                                            .resizable()
                                            .frame(width: 44, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                    }

                    // Oyuncular (cast)
                    if !detail.credits.cast.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Oyuncular")
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(detail.credits.cast.prefix(10)) { member in
                                        VStack(spacing: 6) {
                                            KFImage(member.profileURL)
                                                .placeholder { Color.umbraSurface }
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 64, height: 64)
                                                .clipShape(Circle())
                                            Text(member.name)
                                                .font(.caption2)
                                                .foregroundStyle(Color.textPrimary)
                                                .lineLimit(1)
                                            Text(member.character)
                                                .font(.caption2)
                                                .foregroundStyle(Color.textSecondary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 72)
                                    }
                                }
                            }
                        }
                    }
                    
                }
                .padding(.horizontal)
            }
        }
    }
}

extension Provider {
    var logoURL: URL? {
        guard let logoPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w92\(logoPath)")   // küçük logo
    }
}

extension CastMember {
    var profileURL: URL? {
        guard let profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(profilePath)")
    }
}

#Preview {
    DetailView(movieID: 693134)   // örnek: Dune Part Two
        .preferredColorScheme(.dark)
}
