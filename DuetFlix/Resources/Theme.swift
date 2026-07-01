//
//  Theme.swift
//  DuetFlix
//
//  Tasarım token'ları — renk, boşluk, köşe yarıçapı sabitleri.
//  Tek doğru kaynak: docs/DESIGN.md
//

import SwiftUI

// MARK: - Renk paleti (Assets'teki color set'lere bağlı)

extension Color {
    /// Zemin — umbra siyahı `#08060b`
    static let umbraBackground = Color("UmbraBlack")
    /// Kart / yüzey `#14101a`
    static let umbraSurface = Color("Surface")
    /// Yükseltilmiş yüzey `#1b1524`
    static let umbraSurfaceElevated = Color("SurfaceElevated")

    /// Marka vurgusu — akkor turuncusu `#ff7a00`
    static let ember = Color("Ember")
    /// Açık ember `#ffd089`
    static let emberLight = Color("EmberLight")
    /// Koyu ember `#ff5400`
    static let emberDark = Color("EmberDark")

    /// Ana metin `#f4f1f7`
    static let textPrimary = Color("TextPrimary")
    /// İkincil / sönük metin `#8a8194`
    static let textSecondary = Color("TextSecondary")

    /// Puan yıldızı — altın `#ffc107`
    static let ratingStar = Color("Star")
}

// MARK: - Tasarım sabitleri

enum Theme {

    /// 4pt ızgara üzerine boşluk ölçeği.
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    /// Köşe yarıçapları (DESIGN.md: kart ~16-20pt).
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let card: CGFloat = 18
        static let pill: CGFloat = 999
    }

    /// Köşelerdeki yumuşak turuncu ortam ışıması (marka hissi).
    static let ambientGlow = RadialGradient(
        colors: [Color.ember.opacity(0.35), Color.clear],
        center: .topLeading,
        startRadius: 0,
        endRadius: 420
    )
}
