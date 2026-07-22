# App Store Review — DuetFlix

App Store Connect'te gönderim sırasında dolduracağın alanlar için hazır cevaplar.

---

## 1) App Review Information → Notes (inceleyiciye not)

Bu metni "Notes" alanına yapıştır. İnceleyicinin Duo'yu tek cihazla test edememe
sorununu baştan çözer.

```
Thank you for reviewing DuetFlix.

No account or login is required — the app signs in anonymously (Firebase) automatically.

=== HOW TO TEST DUO MATCHING ON A SINGLE DEVICE (demo mode) ===
Duo is a real-time feature that normally needs two devices. For review, we added a
built-in demonstration mode so you can experience the full matching flow on one device:

1. On the mode screen, choose "Duo".
2. Enter any name in the name field.
3. In the room-code field, type: 000000  then tap "Join".
4. A room opens with a simulated partner ("Demo Partner") already inside, so the
   "Start" button is enabled immediately. Tap "Start".
5. Swipe RIGHT (like) on any movie poster. Because the simulated partner has already
   liked every film in the deck, a "match" celebration screen appears instantly,
   confirming the co-selection / matching feature.

(This 000000 demo code is only for review/testing. Real users create a room and share
its code with a friend on a second device.)

=== SOLO MODE ===
Solo mode also works fully on a single device: browse popular films, search, filter,
open a film's details, and add films to a local watchlist.

Film data and images are provided by The Movie Database (TMDB) via their public API,
with attribution shown on the Profile screen and in the app description.

Contact for any questions: bados5561@gmail.com
```

> Not: `bados5561@gmail.com` yerine kendi e-postanı yaz. Ayrıca Firebase projenin gönderim
> sırasında **aktif** olduğundan ve Firestore güvenlik kurallarının **yayınlanmış**
> olduğundan emin ol (kurallar repoda `firestore.rules`).

---

## 2) App Privacy (Veri Toplama anketi)

App Store Connect → App Privacy. "Do you collect data?" → **Yes** (Firebase kimlik/oda
verisi topluyor). Aşağıdaki maddeleri işaretle:

| Veri türü | Toplanıyor mu | Amaç | Kimliğe bağlı mı | Takip için mi |
|---|---|---|---|---|
| **User ID** (anonim Firebase kimliği) | Evet | App Functionality | **Hayır** (bağlı değil) | Hayır |
| **User Content** (Duo'da yazılan görünen ad) | Evet | App Functionality | Hayır | Hayır |
| **Other Usage Data** (beğeni/eşleşme, oda içi) | Evet | App Functionality | Hayır | Hayır |

- **Tracking:** "Are you tracking?" → **No** (reklam/çapraz-uygulama takibi yok).
- İzleme listesi cihazda tutulur, yüklenmez → beyan gerektirmez.
- ⚠️ **Eğer Firebase Analytics eklediysen:** ayrıca "Identifiers → Device ID" ve
  "Usage Data → Product Interaction" işaretlemen gerekir. Analytics kullanmıyorsan
  (önerilen), yukarıdaki tablo yeterli ve **ATT (izleme izni) gerekmez.**

---

## 3) Age Rating (Yaş Sınırı anketi)

Uygulama TMDB'nin popüler filmlerini gösterir; posterler/açıklamalar ara sıra şiddet,
korku veya olgun tema içerebilir. Dürüst cevaplar:

| Soru | Cevap |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | **Infrequent/Mild** |
| Sexual Content or Nudity | **Infrequent/Mild** |
| Profanity or Crude Humor | **Infrequent/Mild** |
| Horror/Fear Themes | **Infrequent/Mild** |
| Mature/Suggestive Themes | **Infrequent/Mild** |
| Alcohol, Tobacco, Drug Use | **Infrequent/Mild** |
| Gambling / Contests | None |
| Unrestricted Web Access | No |
| User-Generated Content | **Yes** (Duo görünen ad) → aşağıya bak |

→ Sonuç muhtemelen **12+**. Emin değilsen bir üst kademeyi (17+) seçmek en güvenlisidir;
düşük seçip içerik uymazsa ret gelir, yüksek seçmek sorun olmaz.

**User-Generated Content (Kural 1.2) notu:** DuetFlix'te tek kullanıcı içeriği, Duo'da
yazılan **görünen addır** ve yalnızca oda koduyla **davet ettiğin** kişi görür — açık/
yabancıyla sosyal akış yoktur. Sigorta olarak uygulamada isimlere **uzunluk sınırı +
basit uygunsuz-kelime kontrolü** eklendi (bkz. DuoView). İncelemede sorulursa: "rooms are
private and invite-only via a code; the only UGC is a display name shown to the invited
partner, with length and basic content limits."

---

## 4) Diğer zorunlu alanlar (hatırlatma)
- [ ] **Privacy Policy URL** — `docs/PRIVACY-POLICY.md` bir sayfaya konup URL girilecek.
- [ ] **Support URL** — iletişim/e-posta içeren basit bir sayfa (zorunlu).
- [ ] **Category:** Entertainment (birincil).
- [ ] **Screenshots:** `design/app-store/final/{en,tr}` (hazır).
- [ ] **App icon 1024:** hazır (asset katalogda).
- [ ] **Description / keywords:** `docs/APP-STORE.md` (hazır).
- [ ] **Encryption (ITSAppUsesNonExemptEncryption):** yalnızca HTTPS kullanıyorsun →
      Info.plist'e `ITSAppUsesNonExemptEncryption = NO` ekle (ihracat uyumluluğu sorusunu atlatır).
