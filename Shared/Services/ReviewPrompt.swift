import Foundation

/// When to ask for a rating: from the second launch on, after a finished
/// project, and no more than once every 30 days. The system decides whether
/// the prompt actually shows.
struct ReviewPrompt {
    static let minimumLaunches = 2
    static let cooldownDays = 30

    var defaults: UserDefaults = .standard

    private let launches = "review.launches"
    private let lastAsked = "review.lastAsked"
    private let pending = "review.pendingMoment"
    private let openedStore = "review.openedStore"

    func recordLaunch() { defaults.set(defaults.integer(forKey: launches) + 1, forKey: launches) }

    func recordPositiveMoment() { defaults.set(true, forKey: pending) }

    func shouldAsk(now: Date = .now) -> Bool {
        guard defaults.bool(forKey: pending), !defaults.bool(forKey: openedStore) else { return false }
        guard defaults.integer(forKey: launches) >= Self.minimumLaunches else { return false }
        guard let last = defaults.object(forKey: lastAsked) as? Date else { return true }
        return now.timeIntervalSince(last) >= Double(Self.cooldownDays) * 86_400
    }

    func markAsked(now: Date = .now) {
        defaults.set(now, forKey: lastAsked)
        defaults.set(false, forKey: pending)
    }

    /// Opening the review page is the one thing that ends the asks.
    func markOpenedStore() { defaults.set(true, forKey: openedStore) }
}
