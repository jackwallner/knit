# Ravel App Store listing and ASO audit

Date: 2026-11-13. Scope: version 1.0.0 draft, store name "Ravel: Knitting Patterns", App Store ID 6834244566. Read-only audit. Nothing in the repo (other than this file) or App Store Connect was changed.

Method: repo files, iTunes Search API (US, plus GB, DE, SE, DK, NO, FI, FR, NL, CA, AU for localization), screenshot PNGs, live competitor screenshots, the live GitHub Pages site (all five URLs return 200). The iTunes lookup for ID 6834244566 returns zero results, which is expected for an unreleased app, so Ravel's own ranking cannot be measured yet. Search-volume numbers are not available from these tools. "Demand" below is inferred from how many ratings the apps ranking for a term have, and "competition" from who holds the top slots. Treat every ranking claim as a hypothesis to confirm with Apple Search Ads Popularity or App Store Connect search-term analytics after launch (no spend needed for the latter).

## Summary: top 8 changes, ranked by expected impact

1. Rewrite the subtitle and keyword field (A-01, A-02). Subtitle "Row Counter & Yarn Stash" replaces "Row Counter, Stash & Patterns" (its "Patterns" repeats the name and adds no index value). Keyword string below drops the wasted "knit" and "yarn", adds "beginner", "cowl", and is exactly 100 characters.
2. Put the growing-fabric counter in screenshot 1 and the sized-pattern page in screenshot 2 (A-07). The counter is the free hook, the strongest visual, and the answer to the highest-intent search ("row counter"). Right now it is third.
3. Mark paid content in the screenshots (A-10, review-risk P1). Screenshots 1, 2 and 5 show library designs that need a subscription with no indicator. Guideline 2.3.2 asks for this.
4. Confirm the App Store Connect fields that are not in the repo (A-11): categories, copyright, review notes, age rating, App Privacy labels, EULA field. `fastlane/metadata` contains only `en-US` text files, so none of these are version controlled or auditable here.
5. Rewrite the first 3 description lines and add the price block (A-04, A-12). Lead with the free counter and the fit promise, state prices, the 7-day trial and the 24-hour renewal sentence.
6. Use the promotional text for the season (A-05). It is 118 of 170 characters and carries no gift-season hook. It can change any time without a review.
7. Fix the screenshot content defects (A-08, A-09): the empty "Gauge" header in frame 1, the near-empty guided frame 2, and the tab bar covering the Hats row plus the cut-off "Cabled Headba" label in frame 5.
8. Add an en-GB localization with a UK keyword set (A-14), and fill an es-MX localization with extra English keywords (A-15). Both need no app translation. Defer German and Nordic locales until the app UI is translated.

## 1. Metadata files (fastlane/metadata/en-US)

| File | Current | Limit | Verdict |
|---|---|---|---|
| name.txt | Ravel: Knitting Patterns (24) | 30 | Fine. Keep. Exact-match name phrase "knitting patterns" is what ranks the #1 result for that term (an app with 4 ratings). |
| subtitle.txt | Row Counter, Stash & Patterns (29) | 30 | "Patterns" duplicates the name. "Stash" is weak alone; "yarn stash" is the searched phrase. |
| keywords.txt | knit,yarn,crochet,sweater,hat,scarf,gauge,needle,project,tracker,pdf,stitch,beanie,shawl,blanket (96) | 100 | 4 characters unused. "knit" is wasted (see below). "yarn" will move to the subtitle. No spaces after commas (good). |
| promotional_text.txt | 118 chars | 170 | 52 characters unused. No seasonal or paid-library hook. |
| description.txt | 1,972 bytes | 4,000 | Opens with a brand statement instead of the hook. No prices, no trial length, no renewal sentence. Has Terms and Privacy links (good). |
| release_notes.txt | "The first release of Ravel." | 4,000 | Fine for 1.0. |
| name/support/privacy/marketing URLs | All 200 OK | n/a | Match the site. See section 4. |

Stemming evidence: for the term "knit" the US results rank "Loopsy - Crochet & Knitting" third, and its only matching word is "Knitting". That suggests Apple folds "knit" and "knitting" together, so "knit" in the keyword field adds nothing once "Knitting" is in the name. Confirm after launch, but the cost of removing it is near zero. The same logic covers plurals: "pattern" is covered by "Patterns", "project" covers "projects", "needle" covers "needles".

Cross-field combination: Apple combines words across name, subtitle and keywords, so a keyword needs to appear only once anywhere. "knitting row counter", "knitting counter", "row counter", "yarn stash" and "knitting patterns" are all formed by the proposed name plus subtitle without repeating any word. "stitch counter" is formed by "stitch" (keywords) plus "counter" (subtitle).

Missing high-intent terms in the current set: "beginner" (the library has five Beginner designs), "counter" is only reachable through the subtitle (kept), "cowl" (three cowl designs). Zero-value or risky terms: "knit", "crochet" in name or subtitle (see section 2).

Description first 3 lines (what shows before "more"): "Ravel is a knitting companion that keeps your place. Tap once for every row and the fabric on screen grows with the one in your hands. FREE, FOR GOOD / Projects..." The first sentence is wasted on a category label the reader already knows from the icon and name. The fit promise (the paid hook) does not appear until line 12 or so.

Root-level metadata: `fastlane/metadata` has no `primary_category.txt`, `secondary_category.txt`, `copyright.txt`, `review_information/` or age-rating config. The Fastfile runs `deliver` with `skip_metadata: false` and no `submission_information` beyond IDFA, so these exist only in App Store Connect. They cannot be audited from here. See A-11.

### Proposed final text

Name (keep): `Ravel: Knitting Patterns`

Subtitle (24): `Row Counter & Yarn Stash`
Alternate (29), if PDF reading should show on the search card: `Row Counter, Yarn Stash & PDF` (then drop `pdf,` from keywords and use the 4 freed characters on `fit,`).

Keywords (exactly 100):
`stitch,tracker,crochet,beginner,sweater,gauge,pdf,needle,project,hat,beanie,scarf,cowl,shawl,blanket`

Promotional text (132 of 170):
`Cast on gifts before the holidays: hats, cowls and scarves sized to the wearer. The row counter, PDF reader and yarn stash are free.`

## 2. Keyword demand and competition (iTunes Search API, US, top 25)

Reading the table: "Top holders" are the apps in positions 1 to 3. "Winnable?" is whether an app with zero ratings could place top 10 given what holds the top 10 now. Evidence for the name-match effect: for "knitting patterns" #1 is "Knitting: Tutorials & Patterns" with 4 ratings; for "knitting app" #3 is "Knitting Nook" with 0 ratings; for "knitting counter" #2 is "Rowvo: Knit & Crochet Counter" with 3 ratings. Exact words in the name and subtitle beat rating counts at this scale.

| Term | Top holders (ratings) | Intent fit for Ravel | Winnable? | Use |
|---|---|---|---|---|
| knitting | Loopsy 17.1k, LooseLoop 292, knitCompanion 6.9k, YarnPal 35k | Broad, mixed with games | Slow, head term | In name (already) |
| knit | Yarn Fever puzzle 120k, Knit Away 25k, Loopsy | Half the results are puzzle games | No | Skip (stemmed to "knitting") |
| row counter | My Row Counter 4.0k, Vivid Counter 150, Knit Row Counter 140, Easy Knitty 422, StitchTally 307 | Direct. Ravel's free hook. | Yes. Positions 2 to 10 are small apps (0 to 422 ratings) | Subtitle |
| knitting counter | My Row Counter 4.0k, Rowvo 3, CozyKnit 64 | Direct | Yes | Name + subtitle combine |
| knitting patterns | Knitting: Tutorials & Patterns 4, kntd 5.3k, LoopCraft 5.6k, Loopsy | The paid product | Yes via exact name match, top 3 to 5 plausible | Name (already) |
| knitting app | Loopsy 17k, LooseLoop 292, Knitting Nook 0, CoKnit 39 | Generic | Yes, name match "Knitting" is enough | Name (already) |
| stitch counter | My Row Counter 4.0k, Vivid Counter 150, StitchTally 307 | Direct (counts rows, not stitches, but the same tool class) | Yes | "stitch" in keywords + "counter" in subtitle |
| yarn stash | Yarn Hoarder 18, YarnWiz 5, YarnBuddy 806, Loopsy 17k | Stash is a free feature | Yes, top 3 holders have under 1k ratings | Subtitle |
| knitting pattern generator | knitCompanion 6.9k, Loopsy, kntd, Ravit 6.1k ($4.99) | Closest to the hero idea but nobody ranks on the phrase itself, the results are fuzzy | Unclear, low volume | Skip as a phrase. "patterns" + "gauge" covers it |
| sweater pattern | KnitsThatFit Sweaters Premium 84 ($14.99), KnitsThatFit Sweaters 126, Skein 0 | Raglan Pullover to 5X. KnitsThatFit is the one direct "sized to you" competitor. | Yes, top holders have 84 to 126 ratings | "sweater" in keywords |
| beginner knitting | LoopCraft 5.6k, YarnPal 35k, CoKnit 39, Knitandnote 190 | Five Beginner designs | Moderate | "beginner" in keywords |
| crochet | YarnPal 35k, Loopsy 17k, Ribblr 598, LoopCraft 5.6k | App has no crochet patterns. Counter and hook sizes do work. | No on the head term. "crochet row counter" is winnable (many 0 to 24 rating apps) | Keywords only (see below) |
| ravelry | kntd 5.3k, Ravit 6.1k, Stashora 15, Unraveled 31, Etsy 7.4M | None. Third-party trademark. | n/a | Never use |
| sock pattern | Sock Studio 0 ($6.99), Sock Pattern Architect 0, then games | Ravel has no sock design | n/a | Do not use. Would be irrelevant keyword (2.3.7) |
| hat pattern | KnitsThatFit Hats 20 ($4.99), Hat Club 7k (shopping), bead apps | Real designs (3 hats + balaclava) but results are shopping and bead apps | Weak intent | "hat,beanie" kept, cheap |
| knit tracker | knitCompanion 6.9k, Stitchlog 0, KnitRow Tracker 1, My Row Counter 4.0k | Direct | Yes | "tracker" in keywords |
| pattern pdf | Generic PDF readers 1k to 9k, Crochet Patterns Row Counter 1.2k | Mixed. Real intent exists but results are generic PDF apps | Low | "pdf" in keywords |
| knitting project | YarnPal 35k, Knit With Me 13, Loopsy, knitCompanion | Projects tab | Moderate | "project" in keywords |

Crochet decision: do not put "crochet" in the name, subtitle or any screenshot. The library is knitting only, so a crocheter who downloads Ravel for patterns finds none, and the counter and hook sizes are the only crochet value. Keep one word, "crochet", in the keyword field: the free row counter and stash work for crochet, the combination "crochet" plus subtitle "Row Counter" forms "crochet row counter" where the field is thin (many 0 to 24 rating apps), and the cost is 7 of 100 characters. Protect conversion by saying in the description that the library is for knitting (done in the proposed description). If Jack prefers zero risk of crochet-pattern disappointment, drop `crochet,` and add `pullover,` (9 chars incl. comma; trim `blanket` to fit).

Ravelry: no use of the word in any metadata, site copy or screenshot today (grep of repo shows only the AGENTS.md note). Keep it that way, and do not copy competitors that carry it in their names.

Competitor names: nothing in the listing names a competitor. Keep it that way (2.3.7 covers other apps' names in keywords). Do not use "KnitsThatFit", "knitCompanion" or "Knit&Note" anywhere.

Recommended strings (final):

- Name: `Ravel: Knitting Patterns` (24)
- Subtitle: `Row Counter & Yarn Stash` (24)
- Keywords: `stitch,tracker,crochet,beginner,sweater,gauge,pdf,needle,project,hat,beanie,scarf,cowl,shawl,blanket` (100)

Phrases the combined name, subtitle and keywords can form without repeating a word: knitting patterns, knitting row counter, knitting counter, row counter, stitch counter, yarn stash, knitting stash, knit tracker (via stemming), knitting tracker, beginner knitting patterns, sweater pattern, hat pattern, scarf pattern, cowl pattern, shawl pattern, blanket pattern, knitting needle, knitting gauge, crochet row counter, knitting project, pdf pattern.

## 3. Screenshots

Source: `~/ios/appstore-screenshots/configs/knit.json` (set `your-size`, 7 frames, `fastlane/screenshots/en-US/*.png`, all 1320 x 2868). Viewed the contact sheet and frames 1 and 3 at full size.

Order today and headlines:

1. "Knitting patterns written to your size" (design page, Raglan Pullover)
2. "Follow your pattern one row at a time" (guided Ribbed Beanie)
3. "Count rows and watch the fabric grow" (counter, 44, red fabric)
4. "Keep your place in any PDF pattern"
5. "Pick a hat, sweater or shawl to knit"
6. "Pick up each project where you stopped"
7. "Check your yarn before you shop"

What works: the headline type is large, condensed and bold, readable at search-card thumbnail size. Headlines are plain benefit statements with no negation hooks. The knitted-fabric rendering is distinctive and the garment drawn as fabric on frame 1 is the best single image in the set. Frame 3's big "44" over red fabric reads at thumbnail size in a way no competitor frame does.

What does not:

- Order. The three visible frames in search results and on the product page fold are 1 to 3. The hero idea (counter drawn as growing fabric) is only fully legible in frame 3. Frame 1 is a form (chips and steppers) that looks like settings. Frame 2 is mostly empty cream with two lines of small gray text over a teal block.
- Frame 1: the "Gauge" header is followed directly by the Cast On button with no controls, so the half of the promise that says "size and gauge" looks broken.
- Frame 2: the instruction ("Knit", "6 of 22 · 88 stitches") is tiny relative to the frame. The stitch count is the proof that the pattern is worked out, and it cannot be read at thumbnail size.
- Frame 5: the floating tab bar sits over the Hats row and the "Cabled Headba" label is cut off by the edge. Both read as defects.
- Frame 4: roughly 40 percent of the page is blank white. Readable but weak.
- Frames 6 and 7 are plain lists. Acceptable as support frames. They do not need to be in the first three.
- Paid content is shown without any indicator on frames 1, 2 and 5 (see A-10).
- All frames share one cream background. Against the white App Store results page, and next to the saturated tiles of the competitors, cream reads as faint. See comparison.

Competitor first screenshots (live from the API): Loopsy (17k ratings) opens with a colorful "Design Craft Create" collage, an "#1 App Store Fiber Arts App" badge and a hero photo. YarnPal (35k) opens with a photographic pink crochet dinosaur on red, "Crochet Your Ideas Into Reality, 500+ Patterns". knitCompanion (6.9k) opens on a gray photo with chart UI and "It's a Game Changer". My Row Counter (4.0k) opens on a black frame with callouts "So Much More than a Row Counter". LoopCraft (5.6k) opens on a yellow frame with a person, a 2026 badge and "Your All-In-One Crochet & Knitting Companion". Everyone leads with photography, awards or breadth, and none shows a counter that does something visually unusual. Ravel's flat, quiet design is a clear differentiator but needs one saturated frame to catch the eye in a results grid. None of the top five show size-to-you. That claim is open ground.

Recommended order and headlines (each fits the existing 2-line header layout; frames 2 to 4 text is unchanged except order):

1. Counter, fabric full height: `Tap a row, watch your knitting grow` (35 chars). Uses "knitting" for text-in-screenshot relevance.
2. Design page: `Knitting patterns written to your size` (unchanged)
3. Guided pattern: `Follow your pattern one row at a time` (unchanged)
4. PDF: `Keep your place in any PDF pattern`
5. Library: `Pick a hat, sweater or shawl to knit`
6. Projects: `Pick up each project where you stopped`
7. Stash: `Check your yarn before you shop`

Visual changes: set frame 1's background to the accent red (#8f2f2c) with cream headline text and keep the others warm paper, so the first tile stands out in the results grid. Recapture the design flow with the Gauge controls visible (scroll the page so the gauge rows sit above the Cast On bar, or capture a state where gauge has values). Recapture guided with the Raglan Pullover cast on at a yoke row so the instruction line and stitch count are large (the seed already has the pdf text "Row 13: Knit, placing 4 raglan markers"). Recapture the library with the tab bar scrolled clear and the horizontal shelf ending on a whole card. After launch, use Product Page Optimization (free) to test the red frame 1 against paper.

## 4. Marketing site (docs/)

Files: `index.html`, `support.html`, `terms.html`, `privacy-policy.html`, `styles.css`, `trending.json`, icons. All five public URLs return 200.

Matches: Support URL in `support_url.txt` is `.../support.html` and exists with a contact email and how-tos. Privacy URL in `privacy_url.txt` and in `Links.privacy` is `.../privacy-policy.html` and exists. The paywall "Terms" button and the description link to Apple's standard EULA (`Links.terms`). `terms.html` also says Ravel uses Apple's standard EULA, lists subscription and lifetime terms and the cancel-24-hours sentence. Footer links are consistent across pages. Policy content matches the app: local-only storage, RevenueCat anonymous ID and purchase records, trending list fetched from the site with no identifiers.

Gaps:

- `index.html` is a three-paragraph page with no screenshot, no App Store badge and no social preview tags. As the Marketing URL it is what a curious user or reviewer sees. After approval, add the App Store link and one screenshot. No taglines needed.
- The page `<title>` is "Ravel: Knitting Patterns" on the home page only. Support, Terms and Privacy titles are fine.
- The public support address is a personal Gmail. That is the developer's call. A role address would be cleaner but is not required.
- The privacy policy says "PDF patterns you add are copied into the app's storage", but the app also imports photos of patterns (`.fileImporter` accepts images, plus `PhotosPicker`). Add "and photos". The privacy policy is otherwise accurate.
- `terms.html` is not linked from the paywall or the description (both go to Apple's EULA). That is acceptable. If a custom EULA is never set in App Store Connect, the Apple standard applies and the two stay consistent.

Copy quality: plain and accurate. "Free, for good" is a fair heading. Nothing to remove.

## 5. App Review risk

- 3.1.2 (subscriptions). Paywall (`PaywallView.swift`): plan rows show term and localized price at body size ("$39.99 a year"), a trial action label ("Try Free for 7 Days"), a footnote "7 days free, then $39.99 a year. Renews until you cancel in Settings.", Restore, Terms (Apple standard EULA) and Privacy buttons. Description has Terms of Use and Privacy links. Risks: (a) the description names no prices or trial length, which is allowed but weaker than it should be, fix in A-04; (b) the paywall footnote omits "payment is charged to your Apple Account at confirmation" and the 24-hour cancel wording (those sit on the website terms and are in the proposed description). Add the one-line standard text to the paywall footer if the app has room, otherwise the description covers it. (c) The plan labels in the paywall are "Yearly", "Monthly", "Lifetime" while the App Store Connect subscription display names should read as the group name "Ravel Patterns" plus term. Fine, but keep them aligned.
- 3.1.1 / 3.1.2. Lifetime is a non-consumable and sits beside subscriptions on one paywall with a price on each. Acceptable.
- 2.3.2. Apps with IAP must make it clear in description, screenshots or previews which content needs a purchase. The description does. Screenshots 1, 2 and 5 do not. Review rarely rejects on this when the description is clear, but it is a cheap fix (A-10).
- 2.3.1 and 2.3.7 (accurate metadata, irrelevant keywords, third-party names). Proposed keywords have no trademarks, no competitor names and no unrelated terms. "crochet" is defensible because the counter and hook sizes are crochet-relevant and the description says the library is knitting only. Do not add "ravelry", "sock" or "etsy".
- 5.1.1 (privacy). Policy URL is present and accurate. No accounts exist, so account-deletion rules do not apply. No camera permission is needed (photos use `PhotosPicker` and the file importer). `ITSAppUsesNonExemptEncryption` is false. App Privacy labels must include RevenueCat's data (purchase history and an app user identifier). Verify in App Store Connect against RevenueCat's published guidance. The listing should state no tracking.
- Claim support for "patterns that write themselves". The shipped copy says "written to your size" and "every cast on, increase and decrease is worked out for your numbers, so the stitch counts add up at any size, from a baby hat to a 5X pullover". The code supports it: `Design.swift` has a Baby head size of 16 in and a 5X raglan (chest 64 in), `Engines.swift` computes stitch counts per design, and `PatternTests` runs every design at every size and yarn weight and checks carry-over of stitch counts. A frozen `planData` copy protects cast-on projects when a subscription lapses, which backs "a pattern you have already cast on stays in your projects". Avoid "AI", "custom designer" and "perfect fit" wording. Keep "gauge" and "swatch" language honest (the Terms page already says to check gauge).
- Review notes: not in the repo. Write that no sign-in is needed, the paywall is reached from the Patterns tab by tapping a locked design, and trial and restore are testable with the sandbox account. Attach the subscriptions to the version (first-time subscriptions are reviewed with the binary).

## 6. Category, age rating, localization

Category (current setting unknown, cannot be read here). Competitors: Loopsy Lifestyle with Utilities, knitCompanion Lifestyle with Productivity, YarnPal Lifestyle with Reference, LoopCraft Lifestyle, My Row Counter Entertainment with Lifestyle (age 9+). Recommend Lifestyle primary and Productivity secondary. Lifestyle is where nearly every knitting app and its audience sits. Productivity fits the project tracker framing. Avoid Entertainment (a 9+ rating and the wrong audience). Secondary category has little search effect, so this is low stakes.

Age rating: the app has no user-generated content, no web browsing, no gambling or contests. Subscriptions do not raise the rating. Expect 4+ with every questionnaire answer "None". Not a Kids app, and the privacy policy says not directed to children under 13.

Localization. The app has no localized strings (no `.xcstrings` or `.lproj`) and pattern text is English knitting shorthand. Translated metadata over an English UI invites "not in my language" reviews, so split by cost:

Phase 1, metadata only, English UI is fine:
1. English (UK). Largest English-speaking market after the US with a deep knitting culture. UK results for "knitting" are weak: top holders Loopsy 814 ratings, LoopCraft 1,305, YarnPal 5,230, versus 17k and 35k in the US. "row counter" in the UK is led by My Row Counter at 526 ratings. A separate en-GB keyword field lets the UK store index "jumper" and "tension" (UK words for sweater and gauge). Units already switch to metric outside the US (`Units.current`).
2. English (Australia) and English (Canada), same text as en-GB or en-US. Cheap extra keyword fields. "knitting" top holders are 342 to 4,293 ratings there.
3. Spanish (Mexico) filled with extra English keywords. Widely reported to be indexed for the US storefront as a second keyword field, Apple does not document it. It is low risk if the words are real features. See A-15.

Phase 2, after translating at least the app chrome and paywall:
4. German (Germany, Austria, Switzerland). Strong hand-knitting culture and the weakest competition seen: "stricken" top holders are LooseLoop 116 ratings, Reihenzähler Stricken 65, addi2go 1,128, Zähl Mich 375, YarnPal 1,815.
5. Swedish and Danish. "stickning" and "strikke" results are almost empty (Ullie 3 ratings, Varvräknare 64, Min strikkejournal 128), with the Nordic yarn retailer Hobbii at 1,655 to 3,535 ratings showing real demand. Norwegian and Finnish show the thinnest competition (the top results are English-named apps with under 20 ratings, or none) but smaller markets. French (Tricoton 133, Compte Rangs 491) and Dutch (top YarnPal 455) are next.

## FINDINGS

### A-01 | name-subtitle | P1 | Subtitle repeats "Patterns" and omits the searched phrase "yarn stash"
Evidence: `subtitle.txt` is "Row Counter, Stash & Patterns". "Patterns" is already in the name, so the second occurrence adds no indexed word. "Stash" alone is less specific than "yarn stash", which has weak top holders (Yarn Hoarder 18, YarnWiz 5, YarnBuddy 806).
Recommendation: `Row Counter & Yarn Stash` (24 characters). Alternate if PDF should show on the card: `Row Counter, Yarn Stash & PDF` (29).

### A-02 | keywords | P1 | Keyword field wastes characters and misses "beginner" and "cowl"
Evidence: current 96 characters: "knit" duplicates "Knitting" in the name (Loopsy ranks #3 for "knit" on the word "Knitting" alone), "yarn" will move into the subtitle, 4 characters are unused, "needle" and "project" are fine, "gauge" is a genuine differentiator. "beginner" is absent despite five Beginner designs and a "beginner knitting" results page led by small apps (CoKnit 39, Knitandnote 190).
Recommendation: replace the whole field with exactly 100 characters, no spaces:
`stitch,tracker,crochet,beginner,sweater,gauge,pdf,needle,project,hat,beanie,scarf,cowl,shawl,blanket`

### A-03 | name-subtitle | P2 | Keep the name; the phrase "knitting patterns" is already exact-match
Evidence: the #1 US result for "knitting patterns" is an app with 4 ratings whose name contains the phrase. "Ravel: Knitting Patterns" gives the same exact match. Swapping to "Ravel: Knitting Row Counter" would trade that for "row counter", which the subtitle already supplies.
Recommendation: keep `Ravel: Knitting Patterns`. If the counter should lead the listing card instead, the fallback is name `Ravel: Knitting Row Counter` (27) with subtitle `Patterns Sized to You` (21), and keywords unchanged. Not recommended because the paid product loses the top word slot.

### A-04 | description | P1 | First three lines lead with a category label instead of the hook
Evidence: line 1 is "Ravel is a knitting companion that keeps your place." The fit promise appears far below. The description is not indexed for search on iOS, so it exists for conversion and for 3.1.2 disclosures.
Recommendation: replace `description.txt` with the following (2,303 characters, no em dashes):

```
Tap once for every row and the knitted fabric on screen grows with the one on your needles. The row counter, your own PDF patterns and your yarn stash are free, work offline and need no account.

Add the Ravel pattern library and every design is written to your measurements and gauge, then followed one row at a time.

FREE, FOR GOOD
• Projects: every piece on your needles, each in its own yarn color
• Row counter: tap anywhere to add a row, one tap to take it back. The count is saved the instant you tap. Already mid-project? Set the row you are on
• Repeats: set the rows in a repeat and see where you are in it
• Your own patterns: add a PDF or photos of a printed pattern, tap a line to mark your place and count rows without leaving the page
• Stash: yarn by weight and skein count, plus needles and crochet hooks in US and metric sizes
• Crochet: the row counter and stash work for crochet rows and hooks too. The pattern library is for knitting

PATTERNS WRITTEN TO YOUR SIZE
Choose a design, enter your measurements and your gauge, and Ravel writes the pattern to fit. Every cast on, increase and decrease is worked out for your numbers, so the stitch counts add up at any size, from a baby hat to a 5X pullover.

Then follow it one row at a time. Each tap shows the next instruction and the stitch count you should have on the needles.

The library has hats, a balaclava, scarves, cowls, a cabled headband, blankets, a dishcloth, handwarmers, leg warmers, a shawl and a top-down raglan pullover. The Trending shelf leads with new designs and what suits the season. Patterns read in inches or centimeters to match your iPhone. The Garter Scarf and the Diagonal Dishcloth are free.

RAVEL PATTERNS
Ravel Patterns unlocks the whole library. Monthly is $6.99 and yearly is $39.99, each with a 7-day free trial for new subscribers. Lifetime access is $79.99 once. Prices vary by region and are shown before you start. Payment is charged to your Apple Account at confirmation of purchase. A subscription renews until you cancel it at least 24 hours before the period ends, in Settings. A pattern you have already cast on stays in your projects.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://jackwallner.github.io/knit/privacy-policy.html
```
Keep prices in this text in step with App Store Connect if they change.

### A-05 | description | P2 | Promotional text is under-used and has no seasonal hook
Evidence: 118 of 170 characters, and it repeats the description. The Trending shelf is already month-aware, and November to December is the gift-knitting peak. Promotional text is editable without a new review.
Recommendation: `Cast on gifts before the holidays: hats, cowls and scarves sized to the wearer. The row counter, PDF reader and yarn stash are free.` (132). Rotate by season using designs that exist (handwarmers, balaclava, chunky cowl).

### A-06 | description | P3 | Release notes
Evidence: "The first release of Ravel." is fine for 1.0.
Recommendation: leave as is. From 1.1 on, name the new designs.

### A-07 | screenshots | P1 | The hero idea is in frame 3, not frames 1 and 2
Evidence: search results and the product page show frames 1 to 3 first. Frame 1 is a settings-style form, frame 2 is mostly empty cream with 12 pt gray text, frame 3 is the large fabric with "44". The counter is free and the highest-intent search ("row counter") is the most winnable, yet its image is third.
Recommendation: new order and headlines: 1 counter `Tap a row, watch your knitting grow`; 2 design page `Knitting patterns written to your size`; 3 guided `Follow your pattern one row at a time`; then PDF, library, projects, stash unchanged. Update `sets[0].frames` order and filenames in `~/ios/appstore-screenshots/configs/knit.json` and re-upload with `fastlane upload_screenshots`.

### A-08 | screenshots | P2 | Frame 1 shows an empty Gauge section; frame 2 hides the proof
Evidence: frame 1 shows "Gauge" with the Cast On button directly below. The stitch count that proves the pattern is worked out ("88 stitches") is tiny on frame 2.
Recommendation: recapture design with the gauge controls visible. Recapture guided on the Raglan Pullover at a yoke step so instruction and stitch count are large. Consider an accent-red background for the new frame 1 so it stands apart from the paper tiles in the results grid, then test it with Product Page Optimization after launch.

### A-09 | screenshots | P2 | Library frame has a cut-off label and the tab bar over content
Evidence: frame 5 shows "Cabled Headba" truncated at the right edge and the floating tab bar covering the second Hats row.
Recommendation: recapture the library with the shelf scrolled so the last visible card is whole and the second hats row clears the tab bar, or crop the capture above the bar.

### A-10 | review-risk | P1 | Paid designs appear in screenshots with no purchase indicator
Evidence: frames 1 (Raglan Pullover), 2 (Ribbed Beanie guided) and 5 (library) show designs that need the Ravel Patterns subscription (only the Garter Scarf and Diagonal Dishcloth are free). Guideline 2.3.2 asks that IAP content be identified in the description, screenshots or previews. The description does, the screenshots do not.
Recommendation: add a small footer pill on frames 1, 2 and 5 reading `Ravel Patterns subscription`, or lead frames 2 and 5 with the free designs (Garter Scarf, Diagonal Dishcloth). The existing description wording already satisfies the guideline, so this is risk reduction rather than a known rejection.

### A-11 | review-risk | P1 | Root metadata and ASC-only fields are unauditable from the repo
Evidence: `fastlane/metadata` has only `en-US`. There is no `primary_category.txt`, `secondary_category.txt`, `copyright.txt`, review information, age rating or privacy details in the repo, and the Fastfile does not send them. They exist only in App Store Connect and cannot be read here.
Recommendation: before submitting, confirm in App Store Connect: primary Lifestyle, secondary Productivity; copyright `2026 Jack Wallner`; age rating questionnaire answered "None" throughout (4+); not Made for Kids; EULA field left on the Apple standard (matches the in-app Terms link and the description); App Privacy labels cover RevenueCat purchase data and an app user identifier with no tracking; review notes say no sign-in is needed and how to reach the paywall and restore; subscriptions and the lifetime IAP attached to the 1.0.0 version; subscription display names and the group name "Ravel Patterns" match the paywall.

### A-12 | review-risk | P2 | Paywall footnote lacks the standard renewal and charge sentences
Evidence: `Offer.disclosure` reads "7 days free, then $39.99 a year. Renews until you cancel in Settings." The charge-at-confirmation and 24-hour cancel wording appear only on the website Terms page. The description fix in A-04 covers the metadata side.
Recommendation: if there is room under the plan rows, extend the footnote to `7 days free, then $39.99 a year. Charged to your Apple Account at confirmation. Renews until you cancel at least 24 hours before the period ends, in Settings.` Keep the price rows as they are.

### A-13 | site | P2 | Home page has no screenshot, App Store link or social preview
Evidence: `docs/index.html` is three paragraphs. It is the Marketing URL. No `og:` or `twitter:` tags.
Recommendation: after approval add the App Store link (`https://apps.apple.com/app/id6834244566`) and one screenshot, plus `og:title`, `og:description` and `og:image` using frame 1. Also edit `docs/privacy-policy.html` "PDF patterns you add" to "PDF patterns and photos you add".

### A-14 | localization | P2 | Add en-GB, en-AU and en-CA with market vocabulary
Evidence: UK, Australian and Canadian competition is thin (UK "knitting" top holders 814 to 5,230 ratings, versus 17k and 35k in the US). Each locale carries its own keyword field. UK knitters say "jumper" and "tension". No app translation is needed. Units already follow the device.
Recommendation: en-GB name and subtitle same as en-US. en-GB keywords (99): `jumper,tension,gauge,stitch,tracker,crochet,beginner,pdf,needle,project,hat,beanie,scarf,cowl,shawl`. en-AU and en-CA can reuse the en-US or en-GB set.

### A-15 | localization | P3 | Use an es-MX locale as a second US keyword field
Evidence: it is widely reported that the US storefront also indexes Spanish (Mexico) metadata. Apple does not document this, so treat it as an experiment. Words must be real features.
Recommendation: es-MX keywords (90), English words that describe real designs and tools: `balaclava,headband,handwarmers,dishcloth,calculator,custom,fit,organizer,wool,planner,hook`. Name and subtitle copy the en-US text. If there is any doubt about review, skip it. Verify in App Store Connect search-term analytics before expanding.

### A-16 | localization | P3 | Translate the app before translating the listing for German and Nordic markets
Evidence: no `.xcstrings` or `.lproj` in the repo; library patterns are written in English abbreviations. German (Reihenzähler Stricken 65 ratings, Zähl Mich 375), Swedish and Danish (Varvräknare 64, Min strikkejournal 128) have the weakest competition seen.
Recommendation: when the app chrome and paywall are translated, add de-DE first, then sv and da, then nb, fi, fr-FR. Do not ship translated listings over an English UI.

### A-17 | review-risk | P2 | Keep Ravelry and competitor names out of every surface
Evidence: US results for "ravelry" are all companion apps that carry the word in their names (kntd, Ravit, Stashora, Unraveled). Nothing in the repo's metadata, site or screenshots uses "Ravelry" or any competitor name today.
Recommendation: no change. Add "ravelry", "knitsthatfit", "knitcompanion" and "knit&note" to the pre-submit keyword check. Jack has decided on the name and this finding does not reopen it.

### A-18 | review-risk | P3 | Category and age rating
Evidence: competitors sit in Lifestyle, with Productivity, Utilities or Reference as secondary. My Row Counter is in Entertainment at 9+.
Recommendation: Lifestyle primary, Productivity secondary, 4+. Do not choose Entertainment.

### A-19 | keywords | P2 | Plan keyword validation after launch
Evidence: all ranking inferences here come from rating counts of today's top holders, not search volume.
Recommendation: in the first two weeks read App Store Connect search-term and impressions data, confirm "row counter", "yarn stash", "sweater pattern" and "beginner" are producing impressions, and swap out any of the 15 keywords with zero impressions. Re-evaluate the stemming assumption for "knit" then.

### A-20 | screenshots | P3 | Test a high-contrast first frame with Product Page Optimization
Evidence: all seven frames use the same cream background. Competitor tiles are saturated (yellow, red, black with photos). Cream on a white results page may blend.
Recommendation: after launch, create a PPO treatment with frame 1 on the accent red (#8f2f2c) with cream text. PPO is free. Keep the winner.
