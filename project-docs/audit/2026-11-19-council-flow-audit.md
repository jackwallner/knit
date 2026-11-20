# Council flow audit, 2026-11-19

End-to-end pass through build 25 before the 1.0.0 submission, as a returning holiday knitter and as a counter-only beginner. Voting seats: Claude Opus, Claude Fable, GPT Sol 6.2 (Anthropic and OpenAI). Outside voice: Gemini Flash (Google), not counted.

## Round 1 (build 25)

| Seat | Score | Ship as is |
| --- | --- | --- |
| Claude Opus | 7/10 | yes |
| Claude Fable | 7/10 | no |
| GPT Sol 6.2 | 7/10 | no |
| Gemini Flash (outside) | 6.5/10 | no |

Agreed: no count loss, the counter and saved count are strong, the design page (size, yardage, first rows before paying) is where people convert. Weak spots: finding a pattern, the first minute after paying, and the listing leading with the counter.

### Fixed in build 26

| Finding | Raised by | Fix |
| --- | --- | --- |
| Trial price and terms off screen on the iPhone Duo inner screen; German terms cut mid sentence (App Review 3.1.2 risk) | Sol, Fable | Plan and terms moved into the fixed bar above the button; the picture shrinks first. The old page measured the picture at full size and switched to a scrolling layout that hid the bottom. |
| Search returns nothing for "hat for kids" or "baby blanket" | Fable | Small words dropped, kids/baby/men/women mapped to sizes, any-word fallback. |
| Second counter resets without asking; a project with only a second count deletes without asking | Sol | Reset asks first; delete asks when the second count is above 0. |
| Reopening a design from the library offers Cast On again and makes a second project at row 0 | Fable, Sol, Flash | The design page finds an unfinished project at the same size and yarn and offers Open Project. |
| Cast-on step never names the needle ("with the smaller needle") | Opus, Fable | Row 0 of a library pattern lists the needles from its materials. |
| Stitch count on a shaping row reads as the count now | Fable, Sol, Flash | Shaping rows say "72 stitches after this round" (or row). |
| Set Row in This Section counts within the run, not the section | Sol | The prompt shows the run position ("6 of 40"), the same numbering as under the instruction. |
| A trial bought in onboarding lands on an empty Projects tab | Fable, Flash | Lands on Patterns. |
| Stash rows show a bare "1" | all | "1 skein". |
| Multi-photo import silently drops a page that fails | Sol | The import stops with the existing error. |
| Trial page rows repeat page 2 | all | Second row now says the row counter, PDFs and stash stay free. |
| Mittens drawing reads as an H | Opus | Mittens silhouette on the trial page and paywall. |
| Listing leads with the counter for a "patterns" search | Opus, Sol, Flash | Sized-pattern shot is 01 in every iPhone and iPad set. |
| "crochet" keyword invites mismatch reviews | Opus, Fable | Removed in every language. |

### Not changed

- Large text paywall pushes the purchase button below the plans (Sol): left for after launch.
- Yearly savings badge (Fable, Flash): pricing decision for Jack.
- Gauge below the fold on the design page (Opus), PDF link on the empty Projects screen (Opus, Flash), stash editor field order (Sol, Flash), listing photo quality (Fable): later.
- Name next to Ravelry (Fable): a judgment for Jack, not a flow defect.
- Seasonal knitters can cast on everything in the trial and cancel ("yours to keep"): pricing, not flow.

## Round 2 (build 26)

| Seat | Score | Ship as is |
| --- | --- | --- |
| Claude Opus | 8.5/10 | yes |
| Claude Fable | 8/10 | yes |
| GPT Sol 6.2 | 8/10 | no (build 26 gate) |
| Gemini Flash (outside) | 8/10 | yes |

Round 1 fixes verified. New defects, fixed in build 27 (26dd75d):

| Finding | Raised by | Fix |
| --- | --- | --- |
| Cast-on row listed notions (markers, waste yarn) as needles | Opus, Fable | Only materials lines with a size in mm. |
| Open Project hidden behind the paywall after a trial lapses | Fable | The matching project is checked before the subscription. |
| Single-round crown decreases still showed a bare count | Sol | "after this round" whenever a row's count differs from the row before. |
| "toddler" dropped Baby Booties; men/women mapped to Adult | Sol, Opus | Toddler matches literally; men/women are ignored words. |
| iPhone Duo listing set led with the PDF shot | Sol | Leads with the sized pattern, then the library. |

Release gate on build 27 (c0204474cc52): PASS, 0 blocking. One paywall sheet flicker candidate was judged clean on a frame-by-frame recording (Q055).

## Round 3 (build 27)

| Seat | Score | Ship as is |
| --- | --- | --- |
| Claude Opus | 9/10 | yes |
| Claude Fable | 9/10 | yes |
| GPT Sol 6.2 | 9/10 | yes |

All five round 2 fixes verified. No new launch blockers.

## Customer fit (c1, build 27)

The seats judged the flow as the seasonal gift knitter we market to (TikTok raccoon hat, App Store search). Opus 8/10, Fable 7/10, Sol 8/10. Fixes went into the fleet alignment below.

## Fleet trial alignment (c2 to c7, build 28)

Jack's ask: the trial page, paywall and locked design button must work like the fleet apps, with Mahj Trainer as the reference (trial start rates Aug 13 to Sep 26: Mahj 31%, Cribbage 24%, Bridge 9%).

| Seat | c2 | c3 | c4 | c5 | c6 | c7 |
| --- | --- | --- | --- | --- | --- | --- |
| Claude Opus | 8.5/10 | 9/10 | 9/10 | 9/10 | 9/10 | 9/10 |
| Claude Fable | 8/10 | 9/10 | 9/10 | 9/10 | 8.5/10 | 9.5/10 |
| GPT Sol 6.2 | 7/10 | 8/10 | 8/10 | 8/10 | 8/10 | 9/10 |

Voting seats from two providers (Anthropic, OpenAI); Gemini Flash read each round as an outside voice.

What changed (b3341bc, f630d9b, 7699954, b3a87de, 61d85d3):

- Trial page: the billed price ("$6.99 a month") is the largest price text, one line of terms under it, reassurance first in the benefits ("Row counter, PDFs and stash stay free", "A pattern you cast on is yours to keep"), quiet Get Started above the button. At accessibility sizes the price and button stay pinned and the links scroll.
- Paywall: "Get Ravel Patterns", yearly first with "Save 52%" and "$3.33 a month" under the billed price, terms pinned over "Start 7-Day Free Trial", the plans fade into the bar. Locked designs say "Try Free for 7 Days", or "Unlock Patterns" with no trial left.
- Everyone lands on Patterns after onboarding; the raccoon hat leads Trending and Free on a fresh install.
- Purchase preflight, ported from Mahj: StoreKit ownership settles first (a reinstall that owns the patterns is not sold again; an unverified match is unresolved), StoreKit asked for the free week at every tap within 3 seconds (a late reply serves the next tap once, and is dropped on a purchase or when the app backgrounds), then, with nothing awaited before Apple's sheet, the plan on screen, the store price and the free week must equal what was tapped. A changed free week redraws every plan and says so. Plan cards and Restore lock while buying; Close and Get Started cancel; the paywall cannot be swiped away mid purchase.

Deferred by decision: RevenueCat remote copy arms (no baseline yet), the tapped design's name in the paywall, "Cancel in Settings" wording.

c7: all three seats ship. Still to verify by hand on the TestFlight build: a sandbox trial from a fresh account reaches Apple's sheet, a spent-trial account sees "This Apple Account already had its free week.", and Close during the spinner opens no sheet.

Release gate on build 28: PASS at 13f5947 (same app code as build 28), after two journey updates (first run lands on Patterns; the paywall journey scrolls each plan clear of the pinned bar, which on an iPad form sheet covers every plan) and two ledger judgements (Q056 paywall button on a different screen, Q057 the system's relaunch cross-fade). `release.py check`: ready to submit.

2026-11-20, build 28 on an iPhone (TestFlight, through iPhone Mirroring): the trial tap from a fresh account reached Apple's sheet with the tapped terms (Patterns Monthly, 1-week free trial, $6.99 per month), and cancelling it returned to the trial page with no message. Leaving failed: "Get Started" tapped right after the trial button dismissed the page, and Apple's sheet then opened over the Patterns tab. On a phone the preflight takes milliseconds, so the cancel almost never lands before the purchase is asked for, and Apple's sheet cannot be called back. Fixed as Mahj does it: "Get Started" and the paywall's Close are off while a purchase runs. The spent-trial message cannot be checked on this account until a sandbox trial has run out.
