import SwiftUI

/// The one thing Ravel sells: the pattern library. Price first, nothing to set up.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var picked: Offer.Term
    @State private var working = false
    @State private var message: String?
    @State private var buying: Task<Void, Never>?
    private let subscription = SubscriptionService.shared

    init(picked: Offer.Term = .yearly) { _picked = State(initialValue: picked) }

    private var offer: Offer? { subscription.offers.first { $0.term == picked } ?? subscription.offers.first }

    var body: some View {
        // The fleet paywall: the pitch and plans scroll, the terms and the button stay pinned above the home
        // indicator, so no text size or language can push the price or the purchase off screen.
        ScrollView {
            VStack(spacing: 20) {
                hero.frame(height: 72)
                pitch
                benefits
                if subscription.offers.isEmpty { unavailable } else { plans }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Spacer()
                // Off while a purchase runs, like the swipe down: Apple's sheet must never open over another screen.
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 44, height: 44)
                }
                .disabled(working)
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 8)
            .background(Theme.paper)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let offer {
                purchase(offer)
                    .frame(maxWidth: 540)
                    .frame(maxWidth: .infinity)
                    // The plans fade into the terms instead of being cut off by them.
                    .background(alignment: .top) {
                        LinearGradient(colors: [Theme.paper.opacity(0), Theme.paper], startPoint: .top, endPoint: .bottom)
                            .frame(height: 28)
                            .offset(y: -28)
                            .allowsHitTesting(false)
                    }
                    .background(Theme.paper)
            }
        }
        .background(Theme.paper)
        .task { await subscription.loadOffers() }
        // While a purchase runs the paywall cannot be closed or swiped away. If it goes away anyway, the checks
        // before Apple's sheet stop.
        .onDisappear { buying?.cancel() }
        .interactiveDismissDisabled(working)
        .onChange(of: subscription.isPro) { _, isPro in if isPro { dismiss() } }
        .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {}
    }

    private var hero: some View {
        // A shelf of the library: two rows of pieces, each in a different yarn.
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                lead
                Garment(silhouette: .sweater, yarn: .madder)
                Garment(silhouette: .shawl, yarn: .indigo)
            }
            HStack(spacing: 4) {
                Garment(silhouette: .mittens, yarn: .marigold)
                Garment(silhouette: .scarf, yarn: .plum)
                Garment(silhouette: .cowl, yarn: .moss)
            }
        }
        .padding(.horizontal, 12)
        .accessibilityHidden(true)
    }

    /// The newest paid seasonal design in its own colors, or a plain hat before any has arrived.
    @ViewBuilder
    private var lead: some View {
        if let topical = TopicalStore.shared.items.first(where: { !$0.isFree }) {
            let item = LibraryItem.topical(topical)
            Garment(silhouette: item.silhouette, yarn: item.yarn, colorwork: item.preview, stitch: item.stitch)
        } else {
            Garment(silhouette: .hat, yarn: .spruce)
        }
    }

    private var pitch: some View {
        VStack(spacing: 10) {
            Text("Get Ravel Patterns")
                .font(Theme.display(32, weight: .semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            // What the purchase buys, in one line (App Review 3.1.2).
            Text("Every design in the library, written to your measurements and yarn")
                .font(.body)
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
    }

    /// Reassurance first, as on Mahj's paywall: what stays free, then what the plan adds.
    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            point("Row counter, PDFs and stash stay free")
            point("Hats, mittens, scarves and sweaters")
            point("New seasonal designs through the year")
            point("A pattern you cast on is yours to keep")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    private func point(_ text: LocalizedStringKey) -> some View {
        Label { Text(text) } icon: {
            Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(Color.accentColor)
        }
        .font(.body)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Yearly's saving over twelve months of monthly, for its badge.
    private var saving: Int? {
        guard let yearly = subscription.offers.first(where: { $0.term == .yearly }),
              let monthly = subscription.offers.first(where: { $0.term == .monthly }) else { return nil }
        return Offer.saving(yearly: yearly.amount, monthly: monthly.amount)
    }

    private var plans: some View {
        VStack(spacing: 10) {
            ForEach(subscription.offers) { option in
                let isOn = option.id == offer?.id
                Button { picked = option.term } label: { card(option, isOn: isOn) }
                    .buttonStyle(.plain)
                    // The plan she tapped buy on stays the one on screen until Apple's sheet is done.
                    .disabled(working)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                    .accessibilityIdentifier("paywall.\(option.slug)")
            }
        }
    }

    /// A plan: its name (yearly with the one badge on the page), what it bills under it, the billed price beside it.
    private func card(_ option: Offer, isOn: Bool) -> some View {
        let name = HStack(spacing: 8) {
            Text(option.termName).font(.headline)
            if option.term == .yearly, let saving {
                Text("Save \(saving)%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.14), in: Capsule())
            }
        }
        let detail = Text(option.detail).font(.subheadline).foregroundStyle(Theme.secondary)
        // Yearly's per-month figure sits small under the billed amount, which stays the larger (as on Mahj).
        let price = VStack(alignment: .trailing, spacing: 2) {
            Text(option.priceLine).font(.body.weight(.semibold)).monospacedDigit()
            if let perMonth = option.perMonth {
                Text("\(perMonth) a month").font(.caption).foregroundStyle(Theme.secondary).monospacedDigit()
            }
        }
        // Price beside the name, the detail wrapping under it; stacked only at the accessibility sizes.
        return Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 3) { name; price; detail.fixedSize(horizontal: false, vertical: true) }
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) { name; detail.fixedSize(horizontal: false, vertical: true) }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    price.fixedSize()
                }
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(minHeight: 64)
        .background(.primary.opacity(isOn ? 0.09 : 0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.primary, lineWidth: isOn ? 2 : 0) }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// Pinned: the picked plan's terms, then the button that charges them, then the legal links.
    private func purchase(_ offer: Offer) -> some View {
        VStack(spacing: 10) {
            // Every plan's terms are laid out, so the tallest holds the space and picking a plan never moves the button.
            ZStack {
                ForEach(subscription.offers) { option in
                    let isOn = option.id == offer.id
                    Text(option.disclosure)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(isOn ? 1 : 0)
                        .accessibilityHidden(!isOn)
                }
            }
            Button { buy(offer) } label: {
                Group {
                    if working { ProgressView().tint(Theme.onAccent) } else { Text(offer.action) }
                }
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .foregroundStyle(Theme.onAccent)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Color.accentColor, in: Capsule())
            }
            .disabled(working)
            .accessibilityIdentifier("paywall.buy")
            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        // Capped as on the trial page: past this size the pinned bar would crowd out the plans.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private var unavailable: some View {
        VStack(spacing: 14) {
            if subscription.isLoading {
                ProgressView()
            } else {
                Text("Plans could not load")
                    .font(.headline)
                Button("Try Again") { Task { await subscription.loadOffers() } }
                    .frame(minWidth: 88, minHeight: 44)
            }
            footer
        }
        .frame(minHeight: 180)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            link("Restore") { restore() }.disabled(working)
            link("Terms") { openURL(Links.terms) }
            link("Privacy") { openURL(Links.privacy) }
        }
        .font(.footnote)
        .foregroundStyle(Theme.secondary)
        .frame(minHeight: 44)
    }

    /// A footer link whose tap area is a full 44 points tall and wide.
    private func link(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(minWidth: 72, minHeight: 44)
                .contentShape(Rectangle())
        }
    }

    private func buy(_ offer: Offer) {
        working = true
        buying = Task {
            let outcome = await subscription.purchase(offer) { self.offer }
            working = false
            switch outcome {
            case .purchased, .alreadyOwned: dismiss()
            case .cancelled: break
            case .pending: message = String(localized: "Your purchase is waiting for approval")
            case .unconfirmed: message = String(localized: "Your purchase went through. Tap Restore if the patterns stay locked.")
            case .failed: message = String(localized: "The purchase did not go through")
            case .unavailable: message = String(localized: "The App Store could not be reached. Try again when you are online.")
            // The page now shows the live terms and nothing was bought. A spent free week is said out loud, so a
            // second tap knows it is charged today.
            case .termsChanged: message = subscription.spentTrialMessage(offer)
            }
        }
    }

    private func restore() {
        working = true
        Task {
            let result = await subscription.restore()
            working = false
            switch result {
            case .found: dismiss()
            case .cancelled: break
            case .notFound: message = String(localized: "No purchase found on this Apple Account")
            case .failed: message = String(localized: "The App Store could not be reached. Try again when you are online.")
            }
        }
    }
}
