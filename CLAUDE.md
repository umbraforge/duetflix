# DuetFlix — Proje Bağlamı (Claude için)

**DuetFlix**, iki kişinin film posterlerini kaydırarak **ikisinin de beğendiği** filmi
bulduğu ("bu akşam ne izlesek?") bir iOS uygulaması. Sahibi Batuhan'ın ilk ciddi
portfolyo projesi (iOS developer başvuruları / indie hedefi). Stüdyo: **UmbraForge**.

## Önce bunları oku (tek doğru kaynak)
- `docs/PROJE-PLANI.md` — konsept, özellikler, mimari, riskler, monetizasyon
- `docs/DESIGN.md` — tasarım dili, renk/font, onaylanan 6 ekran
- `docs/CODING-PLAN.md` — **adım adım kodlama planı (CP0→...)**, her adım bir commit
- `docs/brand/` — UmbraForge logosu (README/app ikonu için)

## Özet
- **Stack:** SwiftUI + MVVM · TMDB REST API (async/await, Codable) · Firebase
  Firestore + Auth (Duo, gerçek zamanlı) · SwiftData (watchlist) · 11 dil (String Catalog)
- **Tema:** umbra siyahı `#08060b` + akkor turuncusu `#ff7a00`, koyu/sinematik/premium
- **Mod:** Solo (keşif+filtre+öneri+watchlist, eşleştirme YOK) / Duo (lobi+host+swipe+kesişimle eşleşme)
- **Bundle:** `com.umbraforge.DuetFlix` · Repo: `umbraforge/duetflix`

## Çalışma tarzı
- Küçük adım → çalıştığını gör → **commit** (conventional commits). CODING-PLAN'daki sırayı takip et.
- Sırlar/anahtarlar `.gitignore`'da (Secrets.xcconfig). Git'e sızdırma.
- Klasör yapısı: App / Models / ViewModels / Views / Services / Resources / Utilities

## Durum (2026-07-01)
Faz 0 bitti. Repo + Xcode projesi kuruldu. MVVM klasör yapısı + App/ (DuetFlixApp.swift, ContentView.swift içinde) HAZIR.
Proje senkron klasör yapısı (Xcode 16) kullanıyor → dosyaları diskten taşımak güvenli.

**Kararlar:**
- Organization Identifier (`com.umbraforge`) şimdilik ERTELENDİ — engelleyici değil, sonra ayarlanır.
- Batuhan git'i (commit/push) KENDİSİ yapıyor (öğrenmek için) — sen git komutları çalıştırma, ona bırak.

**Sıradaki adım: CP1 — Tema/renkler.**
Batuhan önce CP0'ın ilk commit & push'unu kendi yapacak, sonra CP1'e geçilecek:
- Assets'e renkler: umbra siyahı #08060b, ember #ff7a00, surface, text renkleri
- `Theme.swift` (renk/spacing/corner sabitleri) — docs/DESIGN.md'den
- Koyu mod varsayılan
- commit: `feat: design tokens & theme`
Detaylar: docs/CODING-PLAN.md
