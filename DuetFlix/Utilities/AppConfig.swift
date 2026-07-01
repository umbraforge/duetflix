//
//  AppConfig.swift
//  DuetFlix
//
//  Uygulama yapılandırması — sırlar Info.plist üzerinden (Secrets.xcconfig'ten enjekte).
//  Anahtarlar git'e girmez; bkz. Config/Secrets.example.xcconfig
//

import Foundation

enum AppConfig {

    /// TMDB v4 Read Access Token (Bearer auth ile kullanılır).
    static let tmdbAccessToken = infoValue(for: "TMDBAccessToken")

    /// TMDB v3 API Key (query param `api_key` ile kullanılır).
    static let tmdbAPIKey = infoValue(for: "TMDBAPIKey")

    /// Info.plist'ten string değeri okur; boş/placeholder ise programı erken uyarır.
    private static func infoValue(for key: String) -> String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            !value.isEmpty,
            !value.hasPrefix("YOUR_")
        else {
            assertionFailure("""
            ⚠️ '\(key)' bulunamadı ya da doldurulmadı.
            Config/Secrets.xcconfig dosyasını gerçek TMDB anahtarınla güncelle.
            (Şablon: Config/Secrets.example.xcconfig)
            """)
            return ""
        }
        return value
    }
}
