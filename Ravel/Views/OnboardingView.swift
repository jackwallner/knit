import SwiftUI

/// First launch: two pages of what Ravel does, then the yearly trial. One button in one place advances every
/// page and, on the last, starts the trial; "Get Started" keeps the free app. The tracker never waits on this.
struct OnboardingView: View {
    let finish: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var page = 0
    @State private var rows = 0.0
    @State private var knitted = 0.0
    @State private var working = false
    @State private var message: String?
    @State private var plans = false
    private let subscription = SubscriptionService.shared

    private var yearly: Offer? { subscription.offers.first { $0.term == .yearly } }
    private var onTrial: Bool { page == 2 }

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(page)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
            bar
        }
        .frame(maxWidth: 540)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        .task { await subscription.loadOffers() }
        .onChange(of: subscription.isPro) { _, isPro in if isPro { finish() } }
        .fullScreenCover(isPresented: $plans) { PaywallView() }
    }

    @ViewBuilder private var content: some View {
        switch page {
        case 0:
            screen("Tap anywhere to count a row") {
                Fabric(rows: rows, yarn: .madder, markEvery: 0, stitch: 30, showsNeedle: true)
                    .motion(.smooth(duration: 0.4), value: rows)
                    .task { await knit(to: 9) }
            }
        case 1:
            screen("Patterns written to your size") {
                Garment(silhouette: .sweater, yarn: .indigo, progress: knitted)
                    .padding(.horizontal, 40)
                    .motion(.easeInOut(duration: 2.4), value: knitted)
                    .onAppear { knitted = 1 }
            }
        default:
            screen(yearly?.trialDays ?? 0 > 0 ? "Try every pattern free" : "Ravel Patterns") {
                shelf
            } below: {
                VStack(alignment: .leading, spacing: 14) {
                    point("Hats, socks, sweaters and shawls")
                    point("Sized to your measurements and yarn")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 36)
            }
        }
    }

    /// A page: its picture above, one line under it, and anything else under that.
    private func screen(_ title: LocalizedStringKey, @ViewBuilder picture: () -> some View,
                        @ViewBuilder below: () -> some View = { EmptyView() }) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 16)
            picture()
                .frame(maxHeight: 360)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.display(30, weight: .semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .accessibilityAddTraits(.isHeader)
            below()
            Spacer(minLength: 8)
        }
    }

    private var shelf: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Garment(silhouette: .hat, yarn: .spruce)
                Garment(silhouette: .sweater, yarn: .madder)
                Garment(silhouette: .shawl, yarn: .indigo)
            }
            HStack(spacing: 4) {
                Garment(silhouette: .mitts, yarn: .marigold)
                Garment(silhouette: .scarf, yarn: .plum)
                Garment(silhouette: .cowl, yarn: .moss)
            }
        }
        .padding(.horizontal, 24)
    }

    private func point(_ text: LocalizedStringKey) -> some View {
        Label { Text(text) } icon: {
            Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(Color.accentColor)
        }
        .font(.body)
    }

    // MARK: - The bar

    /// Everything that changes height sits above the button, and the footer row is laid out on every page,
    /// so the button keeps one frame from the first page to the trial.
    private var bar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                if onTrial {
                    Text(message ?? yearly?.disclosure ?? "")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Get Started") { finish() }
                        .font(.body)
                        .foregroundStyle(Theme.secondary)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("onboarding.skip")
                }
                dots
            }
            .frame(maxWidth: .infinity)

            Button(action: primary) {
                Group {
                    if working { ProgressView().tint(Theme.onAccent) } else { Text(primaryTitle) }
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
            .padding(.top, 16)
            .accessibilityIdentifier("onboarding.next")

            footer
                .padding(.top, 4)
                .opacity(onTrial ? 1 : 0)
                .allowsHitTesting(onTrial)
                .accessibilityHidden(!onTrial)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.primary.opacity(index == page ? 0.7 : 0.18))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityHidden(true)
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

    private func link(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(minWidth: 72, minHeight: 44)
                .contentShape(Rectangle())
        }
    }

    private var primaryTitle: String {
        guard onTrial else { return String(localized: "Continue", comment: "Onboarding button to the next page") }
        return yearly?.action ?? String(localized: "Continue", comment: "Onboarding button to the next page")
    }

    // MARK: - Actions

    private func primary() {
        guard onTrial else {
            withAnimation(.smooth(duration: 0.35)) { page += 1 }
            return
        }
        guard let yearly else {
            // Plans have not loaded: the full paywall says so and can retry.
            plans = true
            return
        }
        working = true
        message = nil
        Task {
            let outcome = await subscription.purchase(yearly)
            working = false
            switch outcome {
            case .purchased: finish()
            case .cancelled: break
            case .pending: message = String(localized: "Your purchase is waiting for approval")
            case .unconfirmed: message = String(localized: "Your purchase went through. Tap Restore if the patterns stay locked.")
            case .failed: message = String(localized: "The purchase did not go through")
            }
        }
    }

    private func restore() {
        working = true
        message = nil
        Task {
            let result = await subscription.restore()
            working = false
            switch result {
            case .found: finish()
            case .cancelled: break
            case .notFound: message = String(localized: "No purchase found on this Apple Account")
            case .failed: message = String(localized: "The App Store could not be reached. Try again when you are online.")
            }
        }
    }

    /// Knits the sample fabric a row at a time, the way the counter does.
    private func knit(to target: Double) async {
        while rows < target {
            try? await Task.sleep(for: .milliseconds(420))
            guard !Task.isCancelled else { return }
            rows += 1
        }
    }
}
