# DuetFlix — Para Modeli (kilitli karar)

> İlk karar 2026-07-07, **revize 2026-07-23** (pazarlamacı/analist gözden geçirme).
> Reklam **yok**. Model: **freemium + tek seferlik "DuetFlix Plus" kilidi** (abonelik YOK).
> Uygulama: CP19 (StoreKit 2), Apple Developer hesabı aktif.

## İlkeler (neden böyle)
1. **Değer anı = "EŞLEŞTİNİZ!" ekranı.** Kullanıcı ödemeden önce en az bir kez yaşamalı.
2. **Düşük kullanım sıklığı** ("bu akşam ne izlesek", haftada 1-3 kez) → **abonelik yanlış araç.**
   İnsanlar seyrek açtıkları bir araca aylık/yıllık ödemekten nefret eder → churn + 1-yıldız.
   Değer bir **özellik kilidi**, içerik akışı değil → **tek seferlik satın alma** doğru araç.
3. **Kısıtlama değil GENİŞLETME sat** ("hakkın bitti" değil "daha fazlasını aç"), ama premium
   özelliğe **tadımlık** ver (ilk birkaç kullanım bedava) → arzuyu ödemeden önce yaşat.
4. **Reklam yok:** düşük sıklıkta gelir getirmez, premium hissi öldürür, ATT/App Privacy'yi bozar.
5. **En az sinir bozan model** kazanır: tek ödeme = tekrarlayan ödeme kaygısı yok, az iade.

## Kademe

| | **Bedava** | **DuetFlix Plus** |
|---|---|---|
| Solo (keşfet / ara / detay / **fragman**) | ✅ tam | ✅ |
| **Duo — 2 kişi** | ✅ **sınırsız** (çekirdek hep bedava) | ✅ |
| İzleme listesi | sınırsız / cömert | sınırsız |
| **Streaming filtresi** ("Servislerim'dekiler") | ✅ **ilk 2 kullanım** sonra paywall | ✅ sınırsız |
| **Grup odası (3-4 kişi)** | ✅ **katılan** olarak bedava | ✅ **kuran (host)** olarak açar |

Tek yetki: **`isPlus`** (tek ürün aktifse açılır).

### Host-pays kuralı (grup odaları)
3-4 kişilik oda **kurmak** Plus ister; **katılmak** her zaman bedava. Böylece yeni kullanıcı
grup özelliğini bedava deneyimler → değeri görür → dönüşür. Viral büyüme korunur.

### Streaming filtresi tadımlığı
Bedava kullanıcı filtreyi **ilk 2 kez** uygulayabilir (UserDefaults sayaç, toplam/lifetime).
3. denemede → paywall. Fikir: "kısıtla" değil "denet, sonra aç".

## Fiyat (tek ürün, tek seferlik)

| Ürün | Product ID | Fiyat | Not |
|---|---|---|---|
| **Plus (ömürlük kilit)** | `com.batuhanaydin.DuetFlix.plus` | **$2.99** global · **₺49.99** TR | non-consumable, tek sefer |

- Apple fiyat tier'ı ~$2.99; **TR override ₺49.99** (TL alım gücü düşük).
- Abonelik grubu / intro-offer / auto-renew **yok** → App Store Connect kurulumu basit.
- **Paid Apps Agreement** yine imzalanmalı (IAP için zorunlu).

## Paywall yerleşimi
Açılışta jenerik duvar **yok**. Bağlamsal, arzu anında:
- Streaming filtresini **3. kez** uygulamaya çalışınca → "Servislerine göre sınırsız filtrele"
- **3. kişiyi** odaya eklemek / 3-4 kişilik oda kurmak isteyince → "Grup gecelerini aç"
- **"Restore Purchases"** her yerde (Apple zorunlu + güven)

## Uygulama planı (CP19)
1. **StoreKit 2 temeli:** `DuetFlix.storekit` config + tek ürün ID + scheme'e ekle.
   `StoreService` (@Observable): `isPlus`, `purchase()`, `restore()`, `Transaction.updates` dinleme.
2. **Paywall ekranı** (tek ürün + Restore + şartlar/gizlilik linki, TR/EN).
3. **Streaming filtresi:** TMDB `/discover/movie?with_watch_providers=…&watch_region=…`.
   "Servislerim" seçimi + 2 bedava kullanım sayacı + bağlamsal paywall.
4. **Grup odaları (3-4, host-pays):** çok-üyeli lobi + N-yönlü kesişim ("herkes beğendi") +
   3-4 avatar UI. Oda kurarken `isPlus` şartı; katılan serbest.

## Hesap tarafı (App Store Connect)
- 1 IAP ürünü oluştur (`...plus`), fiyat tier + TR override ₺49.99.
- Paid Apps Agreement imzala.
- Paywall zorunlu bilgiler: fiyat, "tek seferlik satın alma", gizlilik/şartlar linki, Restore.
