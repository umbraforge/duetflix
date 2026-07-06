//
//  LocalizationManager.swift
//  DuetFlix
//
//  Uygulama içi dil yönetimi (cihaz dilinden bağımsız): kullanıcı EN/TR seçer
//  seçim UserDefaults'ta saklanır

import Foundation

enum AppLanguage: String, CaseIterable {
    case tr, en
    var flag: String { self == .tr ? "🇹🇷" : "🇬🇧" }
    var label: String { self == .tr ? "TR" : "EN" }
    // TMDB API dil kodu
    var tmdbCode: String { self == .tr ? "tr-TR" : "en-US" }
    // Tarih/sayı biçimlendirme için Locale
    var locale: Locale { Locale(identifier: self == .tr ? "tr_TR" : "en_US") }
}

@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()
    private static let storageKey = "app_language"

    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey) }
    }

    private init() {
        // Kayıtlı seçim varsa onu, yoksa cihaz diline göre (tr → tr, diğer → en) başla
        if let saved = UserDefaults.standard.string(forKey: Self.storageKey),
           let lang = AppLanguage(rawValue: saved) {
            language = lang
        } else {
            let deviceIsTurkish = Locale.preferredLanguages.first?.hasPrefix("tr") ?? false
            language = deviceIsTurkish ? .tr : .en
        }
    }

    // Anahtardan mevcut dildeki metni döndür (yoksa anahtarın kendisine düş)
    func t(_ key: String) -> String {
        guard let entry = LocalizedStrings.table[key] else { return key }
        return language == .tr ? entry.tr : entry.en
    }
}

// Kısa kullanım: L("key")
func L(_ key: String) -> String { LocalizationManager.shared.t(key) }

// Format'lı kullanım (sayı/isim): Lf("matches.count", 3) → "3 films..." / "3 film..."
// Tablodaki metinde %d (sayı) veya %@ (metin) yer tutucusu bulunur.
func Lf(_ key: String, _ args: CVarArg...) -> String {
    String(format: LocalizationManager.shared.t(key), arguments: args)
}
