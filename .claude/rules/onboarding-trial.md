---
paths:
  - "Ravel/Views/OnboardingView.swift"
  - "Ravel/Views/PaywallView.swift"
  - "Shared/Services/SubscriptionService.swift"
  - "Shared/Services/Taste.swift"
  - "RavelUITests/OnboardingUITests.swift"
  - "RavelUITests/PaywallUITests.swift"
  - "RavelTests/OfferCopyTests.swift"
  - "RavelTests/StoreTests.swift"
---

# Onboarding and trial (the fleet flow)

Source: Jack, 2026-11-22. Copy this file into a new app's `.claude/rules/` and adapt the page names.

Every fleet app ends first-run onboarding on a trial page that reads as one more onboarding step, not a paywall. Existing paywalls, plan pickers and in-app trial sheets are separate surfaces and stay as they are.

## The spec

- Onboarding pages come first (value, setup, permissions), then one trial page. No plan cards, no "see all plans", no half-sheet, no timeline hero.
- One button in one place. The trial button sits in the exact spot of Continue: same x, y, width, height and corner radius as on every earlier page. It only changes its label to the trial action. "Same thumb zone" is not enough; a visible shift fails. Prove it with equal frames from AXe or the UI test, not by eye.
- Reserve a fixed-height legal footer slot below the button on every page. It is empty on the earlier pages and holds Restore, Terms and Privacy on the trial page. Reserve the price and terms space above the button the same way.
- The soft exit reads "Get Started". It is secondary, sits above the button and never takes the button's slot. Never "Not now" or "Maybe later".
- One tap on the trial button buys the plan directly and opens Apple's confirm. Fall back to the full paywall only when products failed to load.
- The price line and terms always name the plan the button buys. State the trial length, then the price, then auto-renew.
- Match the app's own onboarding colors, fonts and button shape.
- The monthly plan keeps its free-trial intro offer. Never delete a monthly trial in App Store Connect. Lifetime has no trial.
- Fixes to fit, wording or small layout are fine if the flow is the same. A change to the order of screens, a step added or dropped, or the plan shown needs Jack's yes.

## Ravel today

- `Ravel/Views/OnboardingView.swift`: five pages. Two on what Ravel does (page 0 knits a row on any tap), two questions that order the library (`Taste`, they never hide a design), then the trial page (`trialPage = 4`). The tracker never waits on onboarding.
- One `bar` is laid out the same on every page: dots, "Get Started" (only offered on the trial page), the price and terms, the button, then the Restore, Terms and Privacy footer, hidden but still taking space off the trial page. The button keeps one frame from the first page to the last. At accessibility text sizes the exit and footer scroll with the page and the bar keeps only the price and the button.
- The button reads "Continue" on pages 0 to 3 and the plan's trial action on the last. On a question page it waits for an answer.
- Plan: the onboarding trial sells monthly (1-week free trial). RevenueCat offering metadata `onboarding_plan=yearly` switches it to yearly, as does the DEBUG `-OnboardingPlan yearly` launch argument. Edit it remotely with `scripts/remote.py`.
- An account that already used its free week sees "Get Ravel Patterns" with no trial promise. Offline, the main button just opens the app and "Get Started" is hidden.
- Purchase rechecks the tapped terms and trial eligibility before Apple's sheet. "Get Started" and Close are off while a purchase runs.
- After onboarding everyone lands on Patterns.
- Settled in the knit sessions of 2026-11-16 to 19: no separate onboarding paywall, the fleet's CTA button and "Get Started" exit, billed price as the largest price text, one-line terms. `PaywallView` follows the same look (yearly first with the saving, terms above the button).
- Tests: `RavelUITests/OnboardingUITests.swift` walks the pages; the gate journeys check the button frame at each page.
