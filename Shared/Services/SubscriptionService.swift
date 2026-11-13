import Foundation
import Observation
import RevenueCat

enum RevenueCatConfig {
    /// Public SDK key. It is never configured on a simulator.
    static let apiKey = "appl_REPLACE_ME"
    static let entitlement = "pro"
    static let yearly = "com.jackwallner.knit.yearly"
    static let monthly = "com.jackwallner.knit.monthly"
}

enum Links {
    static let privacy = URL(string: "https://jackwallner.github.io/knit/privacy-policy.html")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let support = URL(string: "https://jackwallner.github.io/knit/support.html")!
}

/// One subscription the paywall can sell.
struct Offer: Identifiable, Equatable, Sendable {
    enum Term: Sendable { case yearly, monthly }

    let id: String
    let term: Term
    /// Localized price for one term, from the store.
    let price: String
    /// Days of free trial this customer can still claim. 0 for none.
    let trialDays: Int

    var termName: String { term == .yearly ? "Yearly" : "Monthly" }
    var priceLine: String { term == .yearly ? "\(price) a year" : "\(price) a month" }
    var action: String { trialDays > 0 ? "Try Free for \(trialDays) Days" : "Subscribe" }
    var disclosure: String {
        (trialDays > 0 ? "\(trialDays) days free, then \(priceLine)." : "\(priceLine).") + " Renews until you cancel in Settings."
    }

    #if DEBUG
    static let samples = [
        Offer(id: RevenueCatConfig.yearly, term: .yearly, price: "$39.99", trialDays: 7),
        Offer(id: RevenueCatConfig.monthly, term: .monthly, price: "$6.99", trialDays: 7),
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
        guard isConfigured, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        guard let current = try? await Purchases.shared.offerings().current else { return }
        let available = current.availablePackages.filter { $0.packageType == .annual || $0.packageType == .monthly }
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(packages: available)
        packages = Dictionary(available.map { ($0.storeProduct.productIdentifier, $0) }) { first, _ in first }
        offers = available
            .map { package in
                let product = package.storeProduct
                let canTrial = eligibility[package]?.status == .eligible
                return Offer(
                    id: product.productIdentifier,
                    term: package.packageType == .annual ? .yearly : .monthly,
                    price: product.localizedPriceString,
                    trialDays: canTrial ? Self.trialDays(product.introductoryDiscount) : 0
                )
            }
            .sorted { $0.term == .yearly && $1.term != .yearly }
    }

    func purchase(_ offer: Offer) async -> Outcome {
        guard isConfigured, let package = packages[offer.id] else {
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
