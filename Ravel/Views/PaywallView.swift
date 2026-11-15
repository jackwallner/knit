import SwiftUI

/// The one thing Ravel sells: the pattern library. Price first, nothing to set up.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var picked: Offer.Term
    @State private var working = false
    @State private var message: String?
    private let subscription = SubscriptionService.shared

    init(picked: Offer.Term = .yearly) { _picked = State(initialValue: picked) }

    private var offer: Offer? { subscription.offers.first { $0.term == picked } ?? subscription.offers.first }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 8)

            // At large text sizes the page scrolls and nothing truncates.
            ViewThatFits(in: .vertical) {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    hero.frame(minHeight: 44, maxHeight: 300)
                    pitch
                    Spacer(minLength: 0)
                    store
                }
                ScrollView {
                    VStack(spacing: 28) {
                        hero.frame(height: 96)
                        pitch
                        store
                    }
                }
            }
        }
        .background(Theme.paper)
        .task { await subscription.loadOffers() }
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
                Garment(silhouette: .mitts, yarn: .marigold)
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
            Garment(silhouette: item.silhouette, yarn: item.yarn, colorwork: item.preview)
        } else {
            Garment(silhouette: .hat, yarn: .spruce)
        }
    }

    private var pitch: some View {
        VStack(spacing: 10) {
            Text("Ravel Patterns")
                .font(Theme.display(34, weight: .semibold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            // What the purchase buys, in one line (App Review 3.1.2).
            Text("Every design in the library, written to your measurements and yarn")
                .font(.body)
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
    }

    @ViewBuilder private var store: some View {
        if subscription.offers.isEmpty { unavailable } else { plans }
    }

    private var plans: some View {
        VStack(spacing: 10) {
            ForEach(subscription.offers) { option in
                let isOn = option.id == offer?.id
                Button { picked = option.term } label: {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Text(option.termName).font(.headline)
                            Spacer(minLength: 12)
                            Text(option.priceLine).font(.body).monospacedDigit()
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.termName).font(.headline)
                            Text(option.priceLine).font(.body).monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .frame(minHeight: 54)
                    .background(.primary.opacity(isOn ? 0.09 : 0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.primary, lineWidth: isOn ? 2 : 0) }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
                .accessibilityIdentifier("paywall.\(option.termName.lowercased())")
            }

            if let offer {
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
                .padding(.top, 8)
                .accessibilityIdentifier("paywall.buy")

                // Every plan's terms are laid out, so the tallest holds the space and
                // picking a plan never moves the rows above.
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
            }
            footer
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
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
            link("Restore") { restore() }
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
        Task {
            let outcome = await subscription.purchase(offer)
            working = false
            switch outcome {
            case .purchased: dismiss()
            case .cancelled: break
            case .pending: message = "Your purchase is waiting for approval"
            case .unconfirmed: message = "Your purchase went through. Tap Restore if the patterns stay locked."
            case .failed: message = "The purchase did not go through"
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
            case .notFound: message = "No purchase found on this Apple Account"
            case .failed: message = "The App Store could not be reached. Try again when you are online."
            }
        }
    }
}
