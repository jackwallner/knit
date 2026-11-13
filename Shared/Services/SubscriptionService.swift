import Foundation
import Observation
import RevenueCat
#if DEBUG && targetEnvironment(simulator)
import StoreKit
#endif

enum RevenueCatConfig {
    /// Public SDK key. It is never configured on a simulator.
    static let apiKey = "appl_jiazUDjlvOWTBBUIRFJlnsorHtP"
    static let entitlement = "pro"
    static let yearly = "com.jackwallner.knit.yearly"
    static let monthly = "com.jackwallner.knit.monthly"
    static let lifetime = "com.jackwallner.knit.lifetime"
}

enum Links {
    static let privacy = URL(string: "https://jackwallner.github.io/knit/privacy-policy.html")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let support = URL(string: "https://jackwallner.github.io/knit/support.html")!
    static let writeReview = URL(string: "https://apps.apple.com/app/id6834244566?action=write-review")!
    static let feedback = URL(string: "mailto:jackwallner@gmail.com?subject=Ravel%20feedback")!
}

/// One way to buy the library: a subscription, or a single payment.
struct Offer: Identifiable, Equatable, Sendable {
    enum Term: Int, Sendable { case yearly, monthly, lifetime }

    let id: String
    let term: Term
    /// Localized price for one term, from the store.
    let price: String
    /// Days of free trial this customer can still claim. 0 for none.
    let trialDays: Int

    var termName: String {
        switch term {
        case .yearly: "Yearly"
        case .monthly: "Monthly"
        case .lifetime: "Lifetime"
        }
    }

    var priceLine: String {
        switch term {
        case .yearly: "\(price) a year"
        case .monthly: "\(price) a month"
        case .lifetime: "\(price) once"
        }
    }

    var action: String {
        if term == .lifetime { return "Buy Lifetime" }
        return trialDays > 0 ? "Try Free for \(trialDays) Days" : "Subscribe"
    }

    var disclosure: String {
        if term == .lifetime { return "One payment of \(price). Every pattern is yours for good." }
        return (trialDays > 0 ? "\(trialDays) days free, then \(priceLine)." : "\(priceLine).") + " Renews until you cancel in Settings."
    }

    #if DEBUG
    static let samples = [
        Offer(id: RevenueCatConfig.yearly, term: .yearly, price: "$39.99", trialDays: 7),
        Offer(id: RevenueCatConfig.monthly, term: .monthly, price: "$6.99", trialDays: 7),
        Offer(id: RevenueCatConfig.lifetime, term: .lifetime, price: "$79.99", trialDays: 0),
    ]
    #endif
}

/// Who can open the paid patterns. The tracker never asks this.
@MainActor
@Observable
final class SubscriptionService {
    enum Outcome: Equatable { case purchased, cancelled, pending, failed }

    static let shared = SubscriptionService()

    private(set) var isPro = false
    private(set) var offers: [Offer] = []
    private(set) var isLoading = false
    @ObservationIgnored private var packages: [String: Package] = [:]
    @ObservationIgnored private var isConfigured = false
    #if DEBUG && targetEnvironment(simulator)
    @ObservationIgnored private var testProducts: [String: StoreKit.Product] = [:]
    #endif

    func canOpen(_ design: Design) -> Bool { design.isFree || isPro }

    /// Development and tests only: grant or drop the entitlement without a purchase.
    func setLocalOverride(isPro: Bool) { self.isPro = isPro }

    func start() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-Pro") { isPro = true }
        if arguments.contains("-MockProducts") { offers = Offer.samples }
        #endif
        configureIfNeeded()
        guard isConfigured else { return }
        Task { for await info in Purchases.shared.customerInfoStream { apply(info) } }
        Task { await loadOffers() }
    }

    func loadOffers() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        guard isConfigured else {
            #if DEBUG && targetEnvironment(simulator)
            if offers.isEmpty { await loadTestStoreOffers() }
            #endif
            return
        }
        guard let current = try? await Purchases.shared.offerings().current else { return }
        let terms: [PackageType: Offer.Term] = [.annual: .yearly, .monthly: .monthly, .lifetime: .lifetime]
        let available = current.availablePackages.filter { terms[$0.packageType] != nil }
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(packages: available)
        packages = Dictionary(available.map { ($0.storeProduct.productIdentifier, $0) }) { first, _ in first }
        offers = available
            .map { package in
                let product = package.storeProduct
                let canTrial = eligibility[package]?.status == .eligible
                return Offer(
                    id: product.productIdentifier,
                    term: terms[package.packageType] ?? .monthly,
                    price: product.localizedPriceString,
                    trialDays: canTrial ? Self.trialDays(product.introductoryDiscount) : 0
                )
            }
            .sorted { $0.term.rawValue < $1.term.rawValue }
    }

    #if DEBUG && targetEnvironment(simulator)
    /// Under StoreKit Testing the simulator sells the products in `Ravel.storekit`, so the real
    /// paywall and purchase flow can be walked without touching RevenueCat.
    private func loadTestStoreOffers() async {
        let terms: [String: Offer.Term] = [RevenueCatConfig.yearly: .yearly, RevenueCatConfig.monthly: .monthly, RevenueCatConfig.lifetime: .lifetime]
        guard let products = try? await StoreKit.Product.products(for: Array(terms.keys)), !products.isEmpty else { return }
        testProducts = Dictionary(products.map { ($0.id, $0) }) { first, _ in first }
        offers = products
            .map { product in
                var days = 0
                if let intro = product.subscription?.introductoryOffer, intro.paymentMode == .freeTrial {
                    let unit = switch intro.period.unit {
                    case .day: 1
                    case .week: 7
                    case .month: 30
                    case .year: 365
                    @unknown default: 0
                    }
                    days = intro.period.value * unit
                }
                return Offer(id: product.id, term: terms[product.id] ?? .monthly, price: product.displayPrice, trialDays: days)
            }
            .sorted { $0.term.rawValue < $1.term.rawValue }
    }

    private func purchaseFromTestStore(_ product: StoreKit.Product) async -> Outcome {
        guard let result = try? await product.purchase() else { return .failed }
        switch result {
        case let .success(verification):
            if case let .verified(transaction) = verification { await transaction.finish() }
            isPro = true
            return .purchased
        case .userCancelled: return .cancelled
        case .pending: return .pending
        @unknown default: return .failed
        }
    }
    #endif

    func purchase(_ offer: Offer) async -> Outcome {
        guard isConfigured, let package = packages[offer.id] else {
            #if DEBUG && targetEnvironment(simulator)
            if let product = testProducts[offer.id] { return await purchaseFromTestStore(product) }
            #endif
            #if DEBUG
            // No store on a simulator: stand in for a purchase so the flow can be walked.
            isPro = true
            return .purchased
            #else
            return .failed
            #endif
        }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return .cancelled }
            apply(result.customerInfo)
            return isPro ? .purchased : .pending
        } catch {
            return (error as? ErrorCode) == .paymentPendingError ? .pending : .failed
        }
    }

    /// True when a subscription was found.
    func restore() async -> Bool {
        guard isConfigured, let info = try? await Purchases.shared.restorePurchases() else { return isPro }
        apply(info)
        return isPro
    }

    private func apply(_ info: CustomerInfo) {
        isPro = info.entitlements[RevenueCatConfig.entitlement]?.isActive == true
    }

    private static func trialDays(_ discount: StoreProductDiscount?) -> Int {
        guard let discount, discount.paymentMode == .freeTrial else { return 0 }
        let unit: Int = switch discount.subscriptionPeriod.unit {
        case .day: 1
        case .week: 7
        case .month: 30
        case .year: 365
        @unknown default: 0
        }
        return discount.subscriptionPeriod.value * unit * max(1, discount.numberOfPeriods)
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        #if targetEnvironment(simulator)
        // Simulator and agent runs never reach the production project: no fake customers.
        return
        #else
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
        isConfigured = true
        #endif
    }
}
