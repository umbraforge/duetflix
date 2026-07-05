//
//  PosterTile.swift
//  DuetFlix
//
//  Poster + alttan başlık — eşleşme listelerinde (canlı ve geçmiş) ortak kart.
//

import SwiftUI
import Kingfisher

struct PosterTile: View {
    let url: URL?
    let title: String

    var body: some View {
        KFImage(url)
            .placeholder { Color.umbraSurface }
            .resizable()
            .aspectRatio(2 / 3, contentMode: .fit)
            .overlay(alignment: .bottom) {
                Text(title)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(
                        LinearGradient(colors: [.black.opacity(0.85), .clear],
                                       startPoint: .bottom, endPoint: .top)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}
