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
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 8)

            // At large text sizes the page scrolls and nothing truncates.
            ViewThatFits(in: .vertical) {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    hero.frame(minHeight: 44, maxHeight: 130)
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
        HStack(spacing: 4) {
            Garment(silhouette: .hat, yarn: .spruce)
            Garment(silhouette: .sweater, yarn: .madder)
            Garment(silhouette: .shawl, yarn: .indigo)
        }
        .padding(.horizontal, 28)
        .accessibilityHidden(true)
    }

    private var pitch: some View {
        VStack(spacing: 10) {
            Text("Ravel Patterns")
                .font(Theme.display(34, weight: .semibold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            Text("Every pattern, written to your size and your yarn, one row at a time.")
                .font(.body)
                .foregroundStyle(.secondary)
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

                Text(offer.disclosure)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
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
        HStack(spacing: 20) {
            Button("Restore") { restore() }
            Button("Terms") { openURL(Links.terms) }
            Button("Privacy") { openURL(Links.privacy) }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(minHeight: 44)
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
            case .failed: message = "The purchase did not go through"
            }
        }
    }

    private func restore() {
        working = true
        Task {
            let found = await subscription.restore()
            working = false
            if found { dismiss() } else { message = "No purchase found on this Apple Account" }
        }
    }
}
