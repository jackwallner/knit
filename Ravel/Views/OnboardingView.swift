import SwiftUI

/// First launch: two pages of what Ravel does, two questions that order the library (`Taste`), then the trial.
/// One button in one place advances every page and, on the last, starts the trial; "Get Started" keeps the
/// free app. The tracker never waits on this.
struct OnboardingView: View {
    let finish: () -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var rows = 0.0
    @State private var knitted = 0.0
    @State private var working = false
    @State private var message: String?
    @State private var buying: Task<Void, Never>?
    @State private var shelf: Design.Shelf?
    @State private var experience: Taste.Experience?
    private static let trialPage = 4
    private let subscription = SubscriptionService.shared

    /// The plan the trial button buys. The price line and terms above it always name this same plan.
    private var plan: Offer? {
        subscription.offers.first { $0.term == subscription.onboardingTerm }
            ?? subscription.offers.first { $0.term != .lifetime }
    }
    private var onTrial: Bool { page == Self.trialPage }
    /// On a question with no answer picked yet: the button waits for one, as on Mahj.
    private var unanswered: Bool { (page == 2 && shelf == nil) || (page == 3 && experience == nil) }
    /// On the trial page while the offer is still on its way: the button waits rather than skip the trial.
    private var waitingForOffer: Bool { onTrial && plan == nil && subscription.isLoading }
    /// The free way out, on the trial page while there is an offer to turn down. Offline, the main button
    /// already opens the app, and a second button doing the same would read as a choice that is not one.
    private var declinable: Bool { onTrial && (plan != nil || subscription.isLoading) }

    var body: some View {
        VStack(spacing: 0) {
            // At the largest text sizes the page scrolls rather than clip. Below them the picture shrinks to make
            // room, and only a page whose words alone outgrow the screen (the trial on a 320 point Display Zoom
            // phone) scrolls, without its picture. The picture's ideal height is 0, so ViewThatFits judges the words.
            Group {
                if typeSize.isAccessibilitySize {
                    ScrollView { pageWithTerms.padding(.vertical, 16) }
                } else {
                    ViewThatFits(in: .vertical) {
                        pageWithTerms
                        ScrollView { pageWithTerms.padding(.vertical, 16) }
                    }
                }
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // The first page does what it says: a tap anywhere on it knits one more row.
                .contentShape(Rectangle())
                .onTapGesture { if page == 0 { rows = min(rows + 1, 60) } }
                .id(page)
                // With Reduce Motion on the next page fades in where it stands; nothing slides.
                .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
            // Sized first, so a page that runs long can never push the button off its frame.
            bar.layoutPriority(1)
        }
        .frame(maxWidth: 540)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        .task { await subscription.loadOffers() }
        .onDisappear { buying?.cancel() }
        // Reaching the trial with no offer (offline at launch): ask the store again rather than end the pitch.
        .onChange(of: page) { _, page in
            if page == Self.trialPage, plan == nil, !subscription.isLoading { Task { await subscription.loadOffers() } }
        }
        .onChange(of: subscription.isPro) { _, isPro in if isPro { finish() } }
    }

    /// The page and, on the trial, its plan and terms at the foot, where they sit just above the button.
    private var pageWithTerms: some View {
        VStack(spacing: 0) {
            if onTrial && typeSize.isAccessibilitySize {
                // Large text: the page scrolls, and the price stays pinned over the button in the bar (Mahj found a
                // free week sold with no price on screen when it scrolled).
                VStack(spacing: 20) {
                    trialTitle
                    points
                    freeExit
                    footer
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            } else {
                // The plan and terms sit in the bar, which never scrolls, so a short screen (an iPhone Duo
                // open, a long language) can push the picture away but never the price.
                content
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch page {
        case 0:
            screen("Tap anywhere to count a row") {
                // One continuous run of rows that comes to rest, so the page is still once it has knit.
                Fabric(rows: rows, yarn: .madder, markEvery: 0, stitch: 30, showsNeedle: true)
                    .motion(.easeOut(duration: rows > 9 ? 0.35 : 1.8), value: rows)
                    .sensoryFeedback(.increase, trigger: rows)
                    .task {
                        try? await Task.sleep(for: .milliseconds(300))
                        rows = 9
                    }
            }
        case 1:
            screen("Patterns written to your size") {
                Garment(silhouette: .hat, yarn: .indigo, progress: knitted)
                    .padding(.horizontal, 40)
                    .motion(.linear(duration: 0.6), value: knitted)
                    .onAppear { knitted = 1 }
            }
        case 2:
            question("What do you want to knit first?", Design.Shelf.allCases.map { ($0, $0.title) }, picked: $shelf, id: "onboarding.shelf")
        case 3:
            question("How long have you been knitting?", Taste.Experience.allCases.map { ($0, $0.title) }, picked: $experience, id: "onboarding.experience")
        default:
            screen(trialTitleKey) {
                pieceGrid
            } below: {
                points.padding(.horizontal, 36)
            }
        }
    }

    /// A page: its picture above, one line under it, and anything else under that.
    private func screen(_ title: LocalizedStringKey, @ViewBuilder picture: () -> some View,
                        @ViewBuilder below: () -> some View = { EmptyView() }) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 16)
            picture()
                .frame(idealHeight: 0, maxHeight: 360)
                // On a short screen the picture gives way first, never the words under it.
                .layoutPriority(-1)
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

    /// A question: its line, then the answers as rows. Picking one marks it; the button moves on.
    private func question<Answer: Hashable>(_ title: LocalizedStringKey, _ answers: [(Answer, String)],
                                            picked: Binding<Answer?>, id: String) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 16)
            Text(title)
                .font(Theme.display(30, weight: .semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 10) {
                ForEach(Array(answers.enumerated()), id: \.offset) { index, answer in
                    let on = picked.wrappedValue == answer.0
                    Button { picked.wrappedValue = answer.0 } label: {
                        HStack(spacing: 12) {
                            Text(answer.1)
                                .font(.body.weight(.medium))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(on ? Color.accentColor : Theme.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Color.primary.opacity(on ? 0.08 : 0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.accentColor.opacity(on ? 1 : 0), lineWidth: 2))
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                    .accessibilityIdentifier("\(id).\(index)")
                }
            }
            .padding(.horizontal, 24)
            Spacer(minLength: 8)
        }
    }

    /// Six pieces from the library, the kind the knitter asked for in the top row.
    private var pieceGrid: some View {
        let yarns: [YarnColor] = [.spruce, .madder, .indigo, .marigold, .plum, .moss]
        let pieces = Self.pieces(leading: shelf)
        return VStack(spacing: 4) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { column in
                        Garment(silhouette: pieces[row * 3 + column], yarn: yarns[row * 3 + column])
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    /// The trial page's six pieces: three of the shelf asked for, then the first three of the usual six
    /// that are not already there. With no answer, the usual six.
    static func pieces(leading shelf: Design.Shelf?) -> [Design.Silhouette] {
        let usual: [Design.Silhouette] = [.hat, .sweater, .shawl, .mittens, .scarf, .cowl]
        let lead: [Design.Silhouette]
        switch shelf {
        case .hats: lead = [.hat, .beret, .earflap]
        case .scarves: lead = [.scarf, .cowl, .shawl]
        case .home: lead = [.blanket, .pillow, .cloth]
        case .accessories: lead = [.mittens, .socks, .bag]
        case .sweaters: lead = [.sweater, .cardigan, .vest]
        case nil: return usual
        }
        return lead + usual.filter { !lead.contains($0) }.prefix(3)
    }

    /// Trial-forward, as on every fleet trial page ("Try Mahj+ free"). An account that already had its free week
    /// is charged today, so its page promises no trial.
    private var trialTitleKey: LocalizedStringKey {
        // No free week left, or no offer could load: the page promises no trial.
        if let plan { return plan.trialDays == 0 ? "Get Ravel Patterns" : "Try Ravel Patterns free" }
        return subscription.isLoading ? "Try Ravel Patterns free" : "Get Ravel Patterns"
    }

    private var trialTitle: some View {
        Text(trialTitleKey)
            .font(Theme.display(30, weight: .semibold))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private var points: some View {
        // What stays free first, as on Mahj's proven page, then why a week covers a gift (it is kept), then what
        // the trial opens. Four rows, so a 667 point phone in German keeps every line.
        VStack(alignment: .leading, spacing: 12) {
            point("Row counter, PDFs and stash stay free")
            point("A pattern you cast on is yours to keep")
            point("Hats, mittens, scarves and sweaters")
            point("Sized for anyone, baby to adult")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func point(_ text: LocalizedStringKey) -> some View {
        Label { Text(text) } icon: {
            Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(Color.accentColor)
        }
        .font(.body)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - The bar

    @ViewBuilder private var terms: some View {
        if onTrial {
            VStack(spacing: 10) {
                if let plan {
                    // The billed amount is the most conspicuous thing about price on the page (App Review 3.1.2(c)
                    // rejected Mahj 1.3.0 when the trial outshone it); one line of terms under it. Cribbity's
                    // approved layout, as on every fleet trial page.
                    VStack(spacing: 2) {
                        Text(plan.priceLine)
                            .font(Theme.display(22, weight: .semibold))
                        Text(plan.disclosure)
                            .font(.caption)
                            .foregroundStyle(Theme.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
                }
                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            // In once the page before has slid away, so the price is never drawn over the page that is leaving.
            .transition(.opacity.animation(.easeOut(duration: 0.15).delay(reduceMotion ? 0.1 : 0.3)))
        }
    }

    /// Laid out the same on every page, the free way out and the footer only shown on the trial,
    /// so the button keeps one frame from the first page to the last.
    private var bar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                dots
                // At the accessibility sizes the free way out and the legal links scroll with the page, as on Mahj,
                // so the pinned bar is only the price and the button.
                if !typeSize.isAccessibilitySize { freeExit }
            }
            .frame(maxWidth: .infinity)
            // The fleet's order: the free way out, then the price right over the button that charges it. The bar grows
            // upward from the bottom, so the button keeps its frame on every page. Pinned at every text size.
            terms.padding(.top, 8)

            // The plan this render shows is the one the tap buys; a reload between draw and tap stops the purchase.
            let drawn = plan
            Button { primary(drawn) } label: {
                Group {
                    if working || waitingForOffer { ProgressView().tint(Theme.onAccent) } else { Text(primaryTitle) }
                }
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .foregroundStyle(Theme.onAccent)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Color.accentColor, in: Capsule())
            }
            .disabled(working || waitingForOffer || unanswered)
            .opacity(unanswered ? 0.4 : 1)
            // The button stands still while the page changes over it: no fade on its label.
            .animation(nil, value: page)
            .padding(.top, 16)
            .accessibilityIdentifier("onboarding.next")

            if !typeSize.isAccessibilitySize {
                footer
                    .padding(.top, 4)
                    .opacity(onTrial ? 1 : 0)
                    .allowsHitTesting(onTrial)
                    .accessibilityHidden(!onTrial)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 8)
        // Opaque, so a page that scrolls at large text sizes never shows through the dots or the price.
        .background(Theme.paper)
        // The bar never scrolls: past this size its text would crowd the page out.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private var freeExit: some View {
        // As in Mahj: off while a purchase runs. Apple's sheet cannot be called back once asked for, and on a phone
        // the checks before it take a few milliseconds, so leaving here let the sheet open over the app.
        Button("Get Started") { finish() }
            .disabled(working)
            .font(.body)
            .foregroundStyle(Theme.secondary)
            .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            .frame(minHeight: 44)
            .opacity(declinable ? 1 : 0)
            .allowsHitTesting(declinable)
            .accessibilityHidden(!declinable)
            .accessibilityIdentifier("onboarding.skip")
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0...Self.trialPage, id: \.self) { index in
                Circle()
                    .fill(.primary.opacity(index == page ? 0.7 : 0.18))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityHidden(true)
    }

    private var footer: some View {
        // Stacked at the accessibility sizes, where three links side by side break mid word.
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            link("Restore") { restore() }.disabled(working)
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
        return plan?.trialAction ?? String(localized: "Continue", comment: "Onboarding button to the next page")
    }

    // MARK: - Actions

    private func primary(_ drawn: Offer?) {
        guard onTrial else {
            guard !unanswered else { return }
            // An answer is kept the moment its page is left, so the library has it whichever way onboarding ends.
            if page == 2 { Taste.shelf = shelf }
            if page == 3 { Taste.experience = experience }
            withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .smooth(duration: 0.35)) { page += 1 }
            return
        }
        guard !waitingForOffer else { return }
        // A reinstall whose subscription is already restored is not sold it again: the button just opens the app.
        guard !subscription.isPro else { finish(); return }
        guard let plan = drawn else {
            // Offline or still loading: no offer to make, so the free app opens. The paywall is a tap away later.
            finish()
            return
        }
        working = true
        message = nil
        buying = Task {
            let outcome = await subscription.purchase(plan) { self.plan }
            working = false
            switch outcome {
            case .purchased, .alreadyOwned: finish()
            case .cancelled: break
            case .pending: message = String(localized: "Your purchase is waiting for approval")
            case .unconfirmed: message = String(localized: "Your purchase went through. Tap Restore if the patterns stay locked.")
            case .failed: message = String(localized: "The purchase did not go through")
            case .unavailable: message = String(localized: "The App Store could not be reached. Try again when you are online.")
            // The page now shows the live terms and nothing was bought. A spent free week is said out loud, so a
            // second tap knows it is charged today.
            case .termsChanged: message = subscription.spentTrialMessage(plan)
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
}
