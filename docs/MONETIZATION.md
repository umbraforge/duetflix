# DuetFlix — Para Modeli (kilitli karar)

> İlk karar 2026-07-07 (tek seferlik satın alma) → **revize 2026-10-28: REKLAM MODELİ.**
> Satın alma (StoreKit / DuetFlix Plus) tamamen kaldırıldı. Gelir **ödüllü reklamdan** gelir.
> Önceki plan git geçmişinde: `f3874d7` (StoreKit2 + Plus).

## Model: ödüllü reklam + filtre hakkı cüzdanı

Ücretli kademe YOK. Tek para birimi **filtre hakkı** (credit):

| | Bedava (herkes) |
|---|---|
| Solo keşfet / ara / detay / **fragman** | ✅ sınırsız |
| Mood satırları + 🎲 Zar at | ✅ sınırsız |
| **Duo — eşleştirme (karışık deste)** | ✅ **sınırsız** |
| İzleme listesi + eşleşme geçmişi | ✅ sınırsız |
| **Gelişmiş filtre** (Solo) | 1 hak / uygulama |
| **Filtreli Duo destesi** (host) | 1 hak / oyun |

- Kurulumda hediye: **5 hak**
- Bir ödüllü reklam: **+3 hak**
- Hak bitince → ödül ekranı ("Reklam izle · +3 hak"). Reklam yarıda kapatılırsa hak verilmez.
- Gönüllü kazanma noktası: **Profil → Filtre hakkı** kartı.

### Neden böyle
1. **Çekirdek değer hep bedava.** "EŞLEŞTİNİZ!" anı, fragman ve izleme listesi hiç kapıya takılmaz —
   uygulamanın sebebi bu, onu reklamla boğmak kullanıcıyı kaçırır.
2. **Sadece marjinal özellik hak yakar.** Filtre, "bu akşam ne izlesek"in üstüne bir konfor katmanı →
   karşılığında 20 saniye reklam istemek adil görünür.
3. **Ödüllü > banner/geçiş.** Düşük kullanım sıklığında banner neredeyse hiç gelir getirmez; geçiş
   reklamı akışı böler. Ödüllüde kullanıcı reklamı **kendi seçer** → şikâyet ve 1-yıldız riski düşük.
4. **Para kapısı yok** → Paid Apps Agreement, IAP ürünü, iade/restore yükü, fiyat lokalizasyonu yok.
5. Takas: reklamsız bir "premium hissi" kaybedilir. İleride istenirse **tek seferlik "Reklamları
   kaldır + sınırsız filtre"** ürünü bu modelin üstüne temiz biçimde eklenebilir (cüzdan zaten var).

## Reklam ağı
- **Google AdMob** — ödüllü reklam birimi. SPM: `googleads/swift-package-manager-google-mobile-ads`
  (ürünler: `GoogleMobileAds` + `UserMessagingPlatform`).
- Şu an **Google test birimi** ile çalışıyor (`ca-app-pub-3940256099942544/1712485313`) —
  canlıya çıkmadan önce gerçek AdMob birimiyle değiştirilecek.
- **ATT (izleme izni) istenmiyor** → IDFA alınmaz → kişiselleştirilmemiş reklam. eCPM daha düşük
  ama App Privacy'de `tracking = false` kalır, ATT dialogu ve ek inceleme yüzeyi yok. Geliri
  artırmak istenirse sonra ATT eklenebilir (o zaman App Privacy + privacy manifest güncellenir).
- **AB/İngiltere rızası:** Google UMP (`ConsentForm.loadAndPresentIfRequired`) açılışta çağrılıyor.

## Kod yerleşimi
| Dosya | Rolü |
|---|---|
| `Services/AdService.swift` | Reklam SDK'sına dokunan **tek** dosya: rıza, yükle, göster, ön-yükle |
| `Utilities/FilterCredits.swift` | Hak cüzdanı (UserDefaults, `@Observable`) |
| `Views/RewardView.swift` | Ödül ekranı (bakiye + "Reklam izle") |
| `FilterViewModel.apply(credits:)` | Solo filtre kapısı |
| `LobbyViewModel.startGame(code:credits:)` | Duo filtreli deste kapısı |
| `Views/ProfileView.swift` | Gönüllü kazanma girişi |

`AdService` ve `FilterCredits` `RootView`'da kurulur, `.environment(...)` ile dağıtılır.
Sheet'ler environment'ı miras almadığı için her sheet'e açıkça enjekte edilir.

## App Store tarafı (yayından önce)
- [ ] Gerçek AdMob app ID + ödüllü birim ID'si (`Info.plist` → `GADApplicationIdentifier`, `AdService.rewardedUnitID`)
- [ ] `Info.plist` → `SKAdNetworkItems` (Google'ın yayınladığı liste)
- [ ] App Store Connect → **App Privacy**: "Identifiers / Device ID" + "Usage Data" → *Third-Party
      Advertising*, **Linked = No, Tracking = No** (ATT istemediğimiz için)
- [ ] Yaş derecelendirme anketinde reklam sorusu
- [ ] `PrivacyInfo.xcprivacy` güncel (DeviceID + AdvertisingData eklendi ✅)
- [ ] Gizlilik politikası metnine reklam paragrafı (`docs/PRIVACY-POLICY.md` + `site/privacy.html`)

## Grup odaları (3-4 kişi) — artık ücretsiz
Eski plan bunu "host-pays" premium özelliği yapıyordu. Satın alma kalktığına göre grup odaları
**herkese bedava** bir özellik olarak yapılacak (v1.1 yol haritası madde 4). Gelir filtre
haklarından gelir; grup odası viral büyüme için açık kalır.
