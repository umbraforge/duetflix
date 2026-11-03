//
//  AdService.swift
//  DuetFlix
//
//  Ödüllü reklam (Google AdMob) sarmalayıcısı. Reklam SDK'sına dokunan TEK dosya burasıdır —
//  ağ değişirse ya da reklam kaldırılırsa sadece bu dosya ve çağrıldığı yerler değişir.
//
//  Kurulum (Xcode'da bir kez):
//   1. SPM paketi: https://github.com/googleads/swift-package-manager-google-mobile-ads
//      Ürünler: GoogleMobileAds + UserMessagingPlatform
//   2. Config/Info.plist → GADApplicationIdentifier (AdMob uygulama ID'si)
//

import Foundation
import GoogleMobileAds
import UserMessagingPlatform
import UIKit

@MainActor
@Observable
final class AdService {
    // Canlı AdMob ödüllü reklam birimi — yalnızca Release derlemelerinde kullanılır.
    static let liveRewardedUnitID = "ca-app-pub-1151576171234354/6938627567"

    // Google'ın örnek test birimi. Yayıncı hesabından bağımsızdır: hesap onayı
    // beklerken bile her zaman dolum yapar.
    static let sampleRewardedUnitID = "ca-app-pub-3940256099942544/1712485313"

    // DEBUG'da HER ZAMAN test birimi kullanılır. Üç derdi birden çözer: hesap onaylanmadan
    // da geliştirme sürer, geliştirirken gerçek reklama tıklama riski kalmaz ve "canlıya
    // çıkarken ID'yi geri almayı unutma" diye bir adım hiç doğmaz (Release hep canlıyı alır).
    static var rewardedUnitID: String {
        #if DEBUG
        sampleRewardedUnitID
        #else
        liveRewardedUnitID
        #endif
    }

    // Test cihazları: bu listedeki cihazlar CANLI birimden bile "Test Ad" etiketli reklam
    // alır → kendi telefonunda canlı kurulumu (App ID + birim ID) gerçek trafik yaratmadan,
    // hesabı riske atmadan doğrularsın. Release'te de geçerli olmalı, çünkü canlı birim
    // yalnızca Release'te kullanılıyor; listede sadece senin cihazın olduğu için başka
    // kullanıcıyı etkilemez. Kimlik, cihazda ilk istekte Xcode konsoluna basılır:
    //   <Google> To get test ads on this device, set: ...testDeviceIdentifiers = @[ @"HASH" ]
    static let testDeviceIDs: [String] = ["e91752d5d3477680a9f8513796e5ee3f"]   // Batuhan'ın iPhone'u

    enum State { case idle, loading, ready, unavailable }

    private(set) var state: State = .idle
    private(set) var isPresenting = false

    private var rewarded: RewardedAd?
    private var presentation: Presentation?   // gösterim boyunca delegate'i canlı tutar

    // Açılışta bir kez: rıza (AB/İngiltere) → SDK başlat → ilk reklamı hazırla.
    func start() async {
        // SDK başlamadan ÖNCE ayarlanmalı, sonra ayarlanırsa ilk istekte etkisiz kalır.
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = Self.testDeviceIDs
        await requestConsent()
        await MobileAds.shared.start()
        await preload()
    }

    // Sıradaki reklamı arka planda yükle → kullanıcı butona basınca beklemesin.
    func preload() async {
        guard rewarded == nil, state != .loading else { return }
        state = .loading
        do {
            rewarded = try await RewardedAd.load(with: Self.rewardedUnitID, request: Request())
            state = .ready
        } catch {
            rewarded = nil
            state = .unavailable
            // Yükleme neden başarısız? (Release'te de basılır → canlı birimi cihazda
            // test ederken hata kodunu görebilmek için. Kullanıcıya görünmez.)
            // Yaygın kodlar: 1 = geçersiz istek (birim ID yanlış),
            // 2 = ağ, 3 = noFill (gösterilecek reklam yok — yeni birim / kısıtlı sunum),
            // 8 = uygulama kimliği eksik veya hatalı.
            let ns = error as NSError
            print("‼️ AdMob yükleme hatası — kod \(ns.code) · \(ns.domain) · \(ns.localizedDescription)")
        }
    }

    // Reklamı göster. Kullanıcı ödülü hak ettiyse (reklamı sonuna kadar izlediyse) true döner.
    // Erken kapatırsa false — hak verilmez.
    func showRewarded() async -> Bool {
        if rewarded == nil { await preload() }
        guard let ad = rewarded, let presenter = Self.topViewController() else { return false }

        rewarded = nil          // her reklam tek kullanımlık
        state = .idle
        isPresenting = true

        // Ödül callback'i SADECE ödül kazanılınca çalışır; reklam kapanınca haberimiz
        // olsun diye ayrıca fullScreenContentDelegate dinleniyor (yoksa burada askıda kalırdık).
        let earned = await withCheckedContinuation { continuation in
            let presentation = Presentation(continuation: continuation)
            self.presentation = presentation
            ad.fullScreenContentDelegate = presentation
            ad.present(from: presenter) { presentation.didEarnReward = true }
        }

        presentation = nil
        isPresenting = false
        await preload()         // bir sonraki için hazırlan
        return earned
    }

    // AB/İngiltere kullanıcıları için reklam rızası (Google UMP). Rıza alınmazsa
    // kişiselleştirilmemiş reklamla devam edilir — akış hata verse de uygulama çalışır.
    private func requestConsent() async {
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try await ConsentForm.loadAndPresentIfRequired(from: Self.topViewController())
        } catch {
            // sessiz — rıza formu gösterilemediyse kişiselleştirilmemiş reklam sunulur
        }
    }

    // Reklamı en üstteki ekrandan sun. Ödül ekranı bir sheet olduğu için
    // rootViewController yetmez; sunulan ekranların en tepesine kadar inilir.
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    // Tek bir reklam gösterimini izler: ödül alındı mı, reklam kapandı mı.
    // SDK delegate'i zayıf tuttuğu için AdService gösterim süresince referansı saklar.
    private final class Presentation: NSObject, FullScreenContentDelegate {
        var didEarnReward = false
        private var continuation: CheckedContinuation<Bool, Never>?

        init(continuation: CheckedContinuation<Bool, Never>) {
            self.continuation = continuation
            super.init()
        }

        // Yalnızca bir kez sürdür — iki kez resume etmek çökme sebebidir.
        private func finish() {
            guard let continuation else { return }
            self.continuation = nil
            continuation.resume(returning: didEarnReward)
        }

        func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
            finish()
        }

        func ad(_ ad: FullScreenPresentingAd,
                didFailToPresentFullScreenContentWithError error: Error) {
            finish()
        }
    }
}
