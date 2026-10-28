//
//  FilterCredits.swift
//  DuetFlix
//
//  Filtre hakkı cüzdanı. Filtre uygulayınca azalır, ödüllü reklam izleyince dolar.
//  UserDefaults'ta kalıcı. @Observable olduğu için bakiye değişince ekranlar kendini yeniler.
//

import Foundation

@MainActor
@Observable
final class FilterCredits {
    static let initialGrant = 5    // ilk kurulumda hediye hak
    static let rewardAmount = 2    // bir reklam kaç hak kazandırır

    private let balanceKey = "filter_credits"
    private let seededKey = "filter_credits_seeded"

    private(set) var balance = 0

    // Bu açılışta ücreti ödenmiş filtreler. Aynı kriterle tekrar filtrelemek yeni bir
    // sonuç üretmediği için ikinci kez hak yakmaz (kullanıcı sonuçlara geri dönebilsin).
    // Bilinçli olarak kalıcı DEĞİL — uygulama yeniden açılınca sıfırlanır.
    private var paidFilters: Set<MovieFilter> = []

    func hasPaid(for filter: MovieFilter) -> Bool {
        paidFilters.contains(filter)
    }

    func recordPaid(_ filter: MovieFilter) {
        paidFilters.insert(filter)
    }

    init() {
        let defaults = UserDefaults.standard
        // İlk açılışta cüzdanı hediye hakla doldur — sadece bir kez, yoksa
        // uygulama her açıldığında hak yenilenirdi.
        if !defaults.bool(forKey: seededKey) {
            defaults.set(true, forKey: seededKey)
            defaults.set(Self.initialGrant, forKey: balanceKey)
        }
        balance = defaults.integer(forKey: balanceKey)
    }

    var isEmpty: Bool { balance <= 0 }

    // Bir hak harca. Bakiye boşsa false döner → çağıran ödül ekranını açar.
    @discardableResult
    func spend() -> Bool {
        guard balance > 0 else { return false }
        balance -= 1
        persist()
        return true
    }

    // Reklam ödülü geldi → hak ekle.
    func grantReward() {
        balance += Self.rewardAmount
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(balance, forKey: balanceKey)
    }
}
