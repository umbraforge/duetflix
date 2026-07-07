//
//  NameGuard.swift
//  DuetFlix
//
//  Duo'da girilen görünen ad için temel sigorta (App Store 1.2 — kullanıcı içeriği).
//  Odalar davetle/özel olduğu için ağır bir filtre gerekmez; uzunluk sınırı + basit
//  kelime kontrolü yeterli.
//

import Foundation

enum NameGuard {
    /// Görünen ad için azami karakter.
    static let maxLength = 20

    /// Engellenecek kelimeler (küçük harf). Varsayılan boş — meşru isimleri yanlışlıkla
    /// engellememek için. İstediğin uygunsuz kelimeleri buraya ekleyerek genişlet:
    /// ör. `["kelime1", "kelime2"]`.
    private static let banned: Set<String> = []

    /// Baştaki/sondaki boşlukları atar ve uzunluğu sınırlar.
    static func trimmed(_ raw: String) -> String {
        String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxLength))
    }

    /// Ad uygun mu (engellenen kelime içermiyor mu)?
    static func isClean(_ name: String) -> Bool {
        let lower = name.lowercased()
        return !banned.contains { !$0.isEmpty && lower.contains($0) }
    }
}
