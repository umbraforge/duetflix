# DuetFlix — Para Modeli (kilitli karar)

> Bu strateji 2026-07-07'de kararlaştırıldı. **Uygulama:** Apple Developer hesabı
> yenilenince hayata geçirilecek (CP19). Reklam **yok**; freemium + "DuetFlix Plus".

## İlkeler (neden böyle)
1. **Değer anı = "EŞLEŞTİNİZ!" ekranı.** Kullanıcı bunu ödemeden önce en az bir kez
   yaşamalı — aha-anından önce paywall yok.
2. **Düşük kullanım sıklığı** ("bu akşam ne izlesek", haftada 1-3 kez) → az oturumu
   *kısıtlamak* bağlı kullanıcıyı sinirlendirir, 1-yıldız getirir. İndie'de **büyüme >
   erken gelir**.
3. **Kısıtlama değil, GENİŞLETME sat:** "hakkın bitti" değil "daha fazlasını aç".
4. **Reklam yok:** düşük sıklıkta gelir getirmez, sinematik/premium hissi öldürür, takip
   SDK'sı App Privacy'yi bozar (ATT). Temiz StoreKit 2 portfolyoda daha iyi.

## Kademe

| | **Bedava** | **DuetFlix Plus** |
|---|---|---|
| Solo (keşfet / ara / detay) | ✅ tam | ✅ |
| **Duo — 2 kişi** | ✅ **sınırsız** (çekirdek hep bedava) | ✅ |
| İzleme listesi | sınırsız / cömert (satış kancası değil) | sınırsız |
| **Duo — grup odası (3-4+ kişi)** | ❌ | ✅ herkesin beğendiği film · viral kanca |
| **Solo gelişmiş filtre** (platform / tür / puan) | ❌ | ✅ "sadece Netflix'imizdekiler" |
| Küratörlü desteler + alt ikon/tema | ❌ | ✅ kalite kancaları |

Tek yetki: **`isPlus`**. Herhangi bir ürün aktifse açılır.

## Fiyat (çapalama ile)

| Ürün | Product ID | Fiyat (global) | Not |
|---|---|---|---|
| Aylık (auto-renew) | `com.batuhanaydin.DuetFlix.plus.monthly` | ~$2.99/ay | **Çapa** — yıllığı ucuz gösterir |
| **Yıllık** (auto-renew) ⭐ | `com.batuhanaydin.DuetFlix.plus.yearly` | ~$9.99/yıl + **7 gün ücretsiz deneme** | **Önerilen/varsayılan** |
| **Ömür boyu** (non-consumable) | `com.batuhanaydin.DuetFlix.plus.lifetime` | ~$24.99 tek sefer | "≈2.5 yıl = sonsuza dek" |

- İki abonelik aynı **subscription group**: `DuetFlix Plus`. Yıllığa Introductory
  Offer → Free → 7 gün.
- **🇹🇷 Türkiye:** dolar tier'ı düşük tutma; TR'ye elle indirimli fiyat (ör. yıllık
  ₺149-199, ömür boyu ₺399 civarı) — TL alım gücü düşük.

## Paywall yerleşimi
Açılışta jenerik duvar **yok**. Bağlamsal, arzu anında:
- Odaya **3. kişiyi** eklemeye çalışınca → "Grup gecelerini aç"
- Kilitli **filtreye** dokununca → filtre değerini gösteren paywall
- **"Restore Purchases"** her yerde görünür (Apple zorunlu + güven)

## Uygulama planı (CP19 — hesap gelince)
1. StoreKit test kurulumu: `DuetFlix.storekit` config + 3 ürün ID + scheme'e ekle
2. `StoreService` (StoreKit 2): `isPlus` entitlement, satın al, restore, `Transaction`
   dinleme
3. Paywall ekranı (3 seçenek + Restore, TR/EN)
4. Kilitleri bağla: Solo filtre + (varsa) liste — bağlamsal paywall
5. **Grup odaları (3-4 kişi)** — ayrı büyük iş: çok-üyeli lobi + N-yönlü kesişim
   ("herkes beğendi") + 3-4 avatar UI

## Hesap gelince App Store Connect'te
- 3 IAP ürününü oluştur (yukarıdaki ID'ler), fiyat tier + TR override
- Yıllığa 7 gün intro offer
- Abonelik grubu + yerelleştirilmiş ad/açıklama (TR/EN)
- Paywall zorunlu bilgiler: fiyat, süre, yenileme, gizlilik/şartlar linki
