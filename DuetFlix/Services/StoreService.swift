//
//  StoreService.swift
//  DuetFlix
//
//  StoreKit 2 — tek seferlik "DuetFlix Plus" kilidi (non-consumable).
//  isPlus tek yetki; satın al / geri yükle / işlem güncellemelerini dinle.
//

import Foundation
import StoreKit

@MainActor
@Observable
final class StoreService {
    // Tek ürün: ömürlük Plus kilidi. App Store Connect'te bu ID ile oluşturulacak.
    static let plusProductID = "com.batuhanaydin.DuetFlix.plus"

    private(set) var product: Product?      // App Store / .storekit config'ten yüklenen ürün
    private(set) var isPlus = false         // kullanıcı Plus'a sahip mi (tek yetki)
    private(set) var isPurchasing = false   // satın alma sürerken buton kilidi

    private var updatesTask: Task<Void, Never>?

    init() {
        // Uygulama açıkken gelen işlem güncellemelerini dinle (başka cihaz, aile paylaşımı,
        // iade/iptal vb.). Dinlemezsek bu durumlar anlık yansımaz.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(update) {
                    await self.refreshEntitlement()
                    await transaction.finish()
                }
            }
        }
    }

    // Ürünü yükle (App Store veya lokal .storekit config)
    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.plusProductID]).first
        } catch {
            // sessiz — ürün yoksa paywall "şu an kullanılamıyor" gösterir
        }
    }

    // Mevcut yetkileri tara → isPlus'ı güncelle. Açılışta + her işlem sonrası çağrılır.
    func refreshEntitlement() async {
        var owned = false
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(entitlement),
               transaction.productID == Self.plusProductID,
               transaction.revocationDate == nil {   // iade edilmişse revocationDate dolu
                owned = true
            }
        }
        isPlus = owned
    }

    // Satın al. Başarılıysa yetkiyi tazele + işlemi kapat.
    func purchase() async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshEntitlement()
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // sessiz — kullanıcı tekrar deneyebilir
        }
    }

    // Satın alımları geri yükle (Apple zorunlu). AppStore.sync + yetki taraması.
    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    // StoreKit 2 JWS imza doğrulaması — doğrulanmamış işlemi reddet.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):   return safe
        case .unverified:           throw StoreError.failedVerification
        }
    }

    enum StoreError: Error { case failedVerification }
}
