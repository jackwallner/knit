# Ravel market research: competitors, reviews, knitter voice, pricing

Researched 2026-11-13. US App Store only. Sources are listed at the end. Nothing was bought and no account was created.

Method and limits (read first):
- App data comes from the iTunes Search/Lookup API and App Store pages (country=us). Rating counts are lifetime US counts.
- Reviews come from the iTunes RSS feed, sortBy=mostRecent, pages 1 to 3 (up to 150 per app). 1,502 reviews were read in total across 19 apps. The window differs by app (YarnPal 150 reviews cover only 2026-08-05 to 2026-11-12, knitCompanion's 150 cover 2021 to 2026), so counts are indicative, not statistics. Keyword counts are regex hits.
- Reddit and Ravelry forums blocked automated fetches (403 / "Blocked"). Reddit evidence below comes from search-engine summaries of mirrors and from knitter blogs. No Reddit quote was read first hand, so Reddit items are labeled as such.
- App Store IAP lists show prices but not billing periods. Where a period is unknown it says so.
- Several names in the brief are not real US App Store competitors today: "KnitPal" (the IAP names inside YarnPal say "Knitpal Premium", so it is a YarnPal sibling), Sweaterly, Knitulator, PatternGenius and Knit Maker return no matching apps. Stitch Fiddle only has a 3-rating "Row Tracker".

---

## (a) The 10 most decision-relevant facts

1. **The category is dominated by crochet-led, hard-paywalled "all-in-one" apps, and their reviews are mostly about money.** YarnPal has 35,226 US ratings (4.71) and Loopsy 17,142 (4.75). In YarnPal's latest 150 reviews, 71 are 1 or 2 stars and 41 of those are about paywall, trial or charges. In Loopsy's latest 150, 67 are 1 or 2 stars and 51 of those are about money. Ravel's "tracker stays free" rule is the opposite of what is being punished.
2. **AI-written patterns are now an active, fresh backlash, and it reaches the app store.** Etsy announced a ban on AI-generated knitting and crochet patterns on 2026-10-22 (proactive enforcement early 2027). Ribblr's co-founder posted "Ribblr says NO to AI patterns" (2026-05-06) and its App Store line is "Real makers. Zero slop." In YarnPal's latest reviews 26 of the 71 low ratings cite AI ("AI slop"). Ravel's engines are deterministic math, which is a real answer, but nothing public says so and "patterns that write themselves" reads like AI.
3. **Knitters mock exactly one failure: numbers that do not add up.** Named failure modes: wrong stitch counts, wrong yardage, patterns that do not match the photo, "off by a stitch" decreases. A deterministic generator gets the same treatment when it errs: a KnitsThatFit buyer wrote it demanded "401 yards of yarn for a men's sweater" then "cast on 24 stitches" (2024-11-09, $14.99 premium). Ravel's test suite (stitch counts carry at every size and weight) is its best proof and is invisible to buyers.
4. **Paywalling the basics is what sinks ratings.** Knit&Note moved stash and counters behind $9.99/mo or $107.99/yr and sits at 3.91 stars on 190 ratings; 23 of its 31 recent low reviews are about money, many from long-time free users ("Now I can't make changes without paying $107 a year", 2026-01-06). My Row Counter and knitCompanion get the same complaint on a smaller scale.
5. **Forced or unclear trials and unwanted charges generate the harshest 1-stars.** Loopsy: "free forever" on the first screen, then a trial that cannot be skipped, then refund fights ("charged the $43 and then refused to refund", 2026-11-09). YarnPal: "my $44 was still taken" after cancelling (2026-11-12). Ravel gates only the library and shows price first, which is the right shape.
6. **Losing data is the top functional killer for tracker apps, and Ravel is local-only.** Sync/backup/lost-data complaints: YarnBuddy 33 of 150 reviews, Loopsy 16, knitCompanion 15, My Row Counter 10 (it even sells a "Restore Backup" IAP at $9.99). Ravel has no iCloud sync, no export and no backup path beyond the device, while its own rule says a row count must never be lost.
7. **Updates that remove or alter content people already paid for or started cause review bombs.** Loopsy removed the paid "Smart Pattern" feature (at least 7 negative reviews, 2026-09-24 to 2026-10-09). Tin Can Knits shipped an update that wiped progress and removed per-size view (11 of its 19 low reviews mention the update). Ravel's frozen per-project plan copy is a real differentiator and is only one sentence in the listing.
8. **Guided, step-by-step instruction with only your size is a proven reason to pay and to love an app.** Loopsy's Smart Pattern ("turned a pdf pattern into workable steps", 2026-09-26) is why people bought annual plans. Tin Can Knits users praise "only shows you the size you're knitting". Ribblr fans praise ticking off one stitch at a time. Ravel's guided mode and measured sizes (raglan to a 66 in chest, XS to 5X) match this, but there is only one sweater in 20 designs.
9. **Price points: $39.99/yr is parity, not a premium; $79.99 lifetime and $6.99 monthly are high.** YarnPal and Loopsy both list $39.99 yearly. YarnBuddy: $14.99/yr, $1.99/mo, $44.99 lifetime. My Row Counter: $2.99/mo, $9.99 to $14.99/yr. Single paid PDFs run $4 to $15 (Tin Can Knits in-app $6 to $9, CustomFit $9.99, Purl Soho about $9.80, Brooklyn Tweed $12 to $15). A pattern-library subscription has plenty of precedent, but knitters also ask for per-pattern purchase ("buy patterns individually in the app instead of subscribing", 2026-01-04).
10. **"Pattern adapts to your size" apps have had almost no App Store traction in 9 to 10 years.** Knitting Genius (since 2017): 52 ratings. KnitsThatFit (since 2015/2016): 126 and 84 ratings. The proven demand is for counters, stash and PDF handling (My Row Counter 3,971, knitCompanion 6,920, Ravit 6,093 at $4.99). Demand for custom fit exists on the web (CustomFit at $9.99 per pattern) but has not been shown in-app. Ravel's free tracker is what earns downloads and ratings; the library earns revenue only if it is credible and fit-critical.

Wrong-path flags (details in section g): (i) marketing "writes itself" with no AI disclaimer (R-01); (ii) a 20-design library of mostly free-everywhere accessories as the main paid hook (R-02, R-07); (iii) local-only data (R-05); (iv) 7-day trial plus $6.99 monthly and $79.99 lifetime without reminders or an à la carte option (R-04, R-10); (v) leading with the growing-fabric visual (R-16).

---

## (b) Competitor table (US App Store, 2026-11-13)

Price/IAP models are from App Store listing pages; periods are unknown unless stated.

| App | ID | Rating | US ratings | Price / IAP model | Last update | Top-line positioning |
|---|---|---|---|---|---|---|
| YarnPal: Crochet & Patterns | 6738537088 | 4.71 | 35,226 | Free; Premium IAPs listed at $3.99, $29.99, $39.99 (a reviewer says $4/week or $40/yr); also "Knitpal Premium" at $3.99 to $49.99 | 2026-11-09 | "All-in-one crochet tutor and pattern maker"; videos, AI-styled imagery; launched 2024-12-19 |
| Loopsy: Crochet & Knitting | 6745416564 | 4.75 | 17,142 | Free; "Loopsy Pro" IAPs $4.99 to $99.99 (reviewers cite 7-day trial then $39.99/yr, a $1.99 first month, and $43 charges) | 2026-11-06 | "All-in-one pattern and stash manager with built-in stitch and row counters"; subtitle "Row Counter, Patterns & Stash"; launched 2025-05-23 |
| knitCompanion | 1058142783 | 4.83 | 6,920 | Free; "Essentials" $29.99, "Setup + Essentials" $29.99 | 2025-12-15 | "Works with ANY PATTERN"; PDF/chart markup, magic markers, Ravelry import |
| Ravit (Ravelry client) | 1234214894 | 4.83 | 6,093 | Paid $4.99, no IAP | 2026-07-24 | "Ravelry on the hop"; unaffiliated Ravelry browser/stash |
| LoopCraft: Crochet & Knitting | 6752294439 | 4.70 | 5,612 | Free; IAPs (prices not retrieved; reviewers say "This pricing is INSANE.", 2026-03-21) | 2026-11-03 | Beginner tutorial and pattern app; launched 2025-10-21 |
| kntd:discover (Ravelry aide) | 1572271760 | 4.79 | 5,251 | Free; AdFree $6.49/yr, $2.29/mo | 2026-11-02 | "Ultimate Ravelry companion"; ads are the main complaint |
| My Row Counter, Knit & Crochet (Annapurnapp) | 1342608792 | 4.84 | 3,971 | Free; premium $2.99/mo, $9.99 to $14.99/yr, "No Ads" $2.99, "Restore Backup" $9.99 | 2026-10-28 | "Row Counter with PDF Import"; Watch, widget, multiple counters |
| Knitting Chart | 1251317736 | 4.35 | 1,306 | Free | 2023-01-18 | Chart maker/reader |
| YarnBuddy | 1267678125 | 4.47 | 806 | Free up to 10 projects; Pro $1.99/mo, $14.99/yr, $44.99 lifetime | 2026-11-05 | "Row counter & stash tracker"; Watch, Live Activity |
| Ribblr | 1529605339 | 4.25 | 598 | Free + free/premium patterns, "Gems" earned by ads; per-pattern purchases | 2026-10-28 | "Real makers. Zero slop."; community and designer marketplace; bans AI patterns |
| StashBot | 928131718 | 4.76 | 328 | Paid $4.99, no IAP | 2026-09-18 | Yarn quantity calculator and counter |
| Knitandnote | 1634163608 | 3.91 | 190 | Free; "Premium" $9.99/mo ($8.90 on the shop page), $107.99/yr, $14.99, $11.90 | 2026-11-10 | "Everything you need for your knitting in one place"; 1,200 to 1,400 patterns; sells yarn kits |
| Tin Can Knits | 6444720146 | 4.08 | 138 | Free + IAP: 30+ free patterns; unlimited projects $36 (or $16 with credit); single patterns $6 to $9; Basics Collection $20 | 2026-10-09 | "Knitting patterns made simple"; one-size view; needs sign-in; mostly online |
| KnitsThatFit Sweaters | 1182812124 | 4.33 | 126 | Free (1 crew-neck, 3 adult sizes); Premium $14.99, Print & PDF $2.99, Schematic $2.99, Stop Ads $0.99 | 2025-03-31 | Custom-fit pullovers and cardigans from gauge and body measures; iPad-first |
| KnitsThatFit Premium | 1051125077 | 4.44 | 84 | Paid $14.99 | 2025-03-31 | Same, paid version |
| Pocket Knitting | 1553071325 | 4.89 | 120 | Free; Pro $5.99 / $8.99; cloud storage $1.99 to $19.99 | 2026-09-24 | PDF/photo patterns, counters, notes; sync is paid |
| Yarn AI: Crochet Patterns | 6749139586 | 4.71 | 82 | Free | 2025-09-10 | "Take a photo of a stitch... ask a question"; AI guidance |
| CozyKnit | 6755319044 | 4.84 | 64 | Free | 2026-11-12 | Counters, stash, notes; newer entrant |
| Cast Along: Knitting Math | 6760704901 | 4.96 | 55 | Free | 2026-11-12 | Gauge and yarn calculators; "No more guessing" |
| Knitting Genius (Annapurnapp) | 1318598164 | 4.23 | 52 | Free; 40+ free patterns | 2026-11-08 | "Personalize the design and size... pattern will adapt"; since 2017 |
| Stash2Go II (Ravelry client) | 1463278276 | 4.67 | 45 | Free; Premium $29.99, ad removal $9.99/yr or $1.99/mo | 2026-11-12 | Ravelry app, runs on Watch and TV |
| Knit Pro - Pattern Maker | 1601194384 | 4.51 | 149 | Free | 2026-10-22 | Video lessons; name promises a pattern maker |
| Patternum | 1536002920 | 3.40 | 25 | Free | 2024-03-06 | Designer-side interactive pattern creator |
| Skein: Knitting Pattern Design | 6780070426 | none | 0 | Free | 2026-11-07 | Designer grading software, XS to 5XL, "computes exact stitch and row counts" |

Official Ravelry app: none. Ravelry's own apps directory states "There is no official Ravelry app" and lists only third-party clients.

Search landscape, 2026-11-13: for "knitting row counter" the top results are My Row Counter, Loopsy, Knit Row Counter (140 ratings, 3.48), Vivid Counter, knitCompanion. For "knitting patterns": kntd:discover, LoopCraft, Loopsy, YarnPal, knitCompanion, Tin Can Knits. For "custom fit sweater pattern" the only knitting hits are KnitsThatFit (126 and 84 ratings). Dozens of 0 to 5 rating row counters were released in 2026, so the plain counter space is crowded and undifferentiated. Ravel's subtitle ("Row Counter, Stash & Patterns") is nearly identical to Loopsy's ("Row Counter, Patterns & Stash").

---

## (c) Review mining per competitor

Quotes are under 15 words, with review dates. "Low" means 1 or 2 stars. Star split is for the sample read.

### YarnPal (150 reviews, 2026-08-05 to 2026-11-12; 51 one-star, 20 two, 20 three, 12 four, 47 five)
- Top complaints: paywall everywhere (53 of 150 mention money; 41 of 71 low ratings), AI content (26 of 71 low), misleading ads that promise patterns not in the app, billing.
- Loved: step-by-step videos for beginners; one reviewer says "The videos are clear and easy to follow." (2026-11-11).
- Cancel / 1-star triggers:
  - "99% of the patterns are 'pro'." (2026-11-04); the same reviewer notes there is no way to filter free from pro.
  - "I cancelled the subscription for this app, and my $44 was still taken." (2026-11-12)
  - "This app is all AI slop." (2026-10-25)
  - "It was incomplete, some steps clearly missed." (2026-10-26, "I believe these patterns are AI created")
  - "some of the patterns are off by a stitch or so" (2026-09-22); same review says the instructions then say to reduce the whole project.
  - Ads show patterns that do not exist in the app: "Pattern in photo doesn't exist!" (2026-09-17).
  - Kids hit the wall: an 11-year-old writes they are not going to pay "just to crochet" (2026-11-11).
- Begging for: a row/stitch counter ("This app is lacking a row and stitch counter.", 2026-09-27), search ("No search site to look up a pattern without scrolling", 2026-09-27), saving patterns ("there is no way to copy/save them", 2026-09-13), content that grows with skill ("Doesn't grow with you", 2026-11-03), yarn amounts per pattern.

### Loopsy (150 reviews, 2026-05-11 to 2026-11-11; 54 one-star, 13 two, 11 three, 10 four, 62 five)
- Top complaints: forced trial / "free" claim (23 of 150), billing and refunds, sync failures (16), crashes (12), removal of Smart Pattern after an update (7+), designer-scraping accusations.
- Loved: row counter and lock-screen widget ("I love the row counter widget on my phone lock screen", 2026-10-09); yarn label scanning ("It actually scans the yarn label and pulls in all the info", 2026-11-05); stash and patterns together; iPhone/iPad sync when it works ("It syncs between my phone and my iPad perfectly", 2026-10-07).
- Cancel / 1-star triggers:
  - "free forever with no indication of conditions" (2026-10-14), then a trial wall at the end of onboarding.
  - "They literally don't let you opt out of the free trial" (2026-09-22)
  - "charged the $43 and then refused to refund" (2026-11-09)
  - "The last update has removed the smart pattern function" (2026-09-28); "Bait and switch!" (2026-09-26)
  - "getting a new phone and losing all of my inventory and projects" (2026-10-09)
  - "This app steals patterns from designers." (2026-09-22)
- Begging for: working sync, backups, a way to try the free tier without the trial, the Smart Pattern back, an Android version ("wish it was available on android", 2026-09-21).

### knitCompanion (150 reviews, 2021-12-03 to 2026-08-26; 32 one-star, 11 two, 14 three, 14 four, 79 five)
- Top complaints: complexity ("renamed knit confusion"), sync/iCloud not working (15), crashes (13), paid tiers, no Watch, no Google Drive.
- Loved: markup and Magic Markers on charts; keeps your place on large patterns; dyslexic user: "I'm dyslexic and can have trouble tracking a line" and it helps (2026-01-28); "I upload all my patterns to KnitCompanion." (2026-08-26).
- Cancel / 1-star triggers:
  - "I found this one of the most complex apps I have ever encountered" (2026-06-25)
  - "lost track of the several rows I had knitted" after sync stopped (2025-09-07)
  - Lifetime buyer: "Bait and switch" after the older app was retired (2026-07-23)
  - Lost PDFs and projects (2024-01-23); "open with" does not offer the app for PDFs (2024-01-13).
- Begging for: Apple Watch, working iCloud sync, mark-complete, print/export.

### My Row Counter (Annapurnapp) (150 reviews, 2026-05-31 to 2026-11-11; 5 one-star, 4 four, 141 five)
- Sample caveat: the recent reviews are 94% five-star, which suggests an in-flow rating prompt that catches happy users.
- Loved: "No frills, but it has everything you need" (2026-11-10); Watch counting ("My favorite feature is counting rows using my apple watch", 2026-10-21); multiple counters and row highlighting; importing patterns from websites; responsive developer. One reviewer contrasts it with prettier apps: "I don't need my tools to be pretty." (2026-10-28)
- Cancel / 1-star triggers: premium update moved existing features behind a paywall ("Make all features free again!", 2026-09-06; "Don't take away the features I already had", 2026-06-21); settings not saved (2026-07-02); blank screen after reinstall (2026-07-03); Ravelry sign-in nags (2026-10-19); ads.
- Begging for: auto-created secondary counters from the pattern (2026-10-28), no ads.

### Ribblr (150 reviews, 2025-03-03 to 2026-11-06; 14 one-star, 11 two, 15 three, 18 four, 92 five)
- Top complaints: slow load and login failures, sign-up errors, paying for patterns ("Patterns are expensive", 2025-12-20), purchased patterns cannot be exported as a PDF ("Purchased patterns can only be opened in the Ribblr app.", 2026-02-15), UI clutter.
- Loved: interactive patterns ("tick off one stitch at time", 2026-10-28, an ADHD reviewer); free patterns; community; fast support.
- Positioning signal: its listing line is "Real makers. Zero slop." and the company bans AI patterns.
- Begging for: working login, a PDF copy of what they bought, reviews visible in the library.

### YarnBuddy (150 reviews, 2023-07-02 to 2026-11-11; 13 one-star, 12 two, 16 three, 33 four, 76 five)
- Top complaints: sync/backup (33 mentions), Apple Watch sync (several), broken yarn database and barcode scanner (2025-05-27, 2025-09-18, 2026-11-07), no developer reply ("NEVER received a response", 2026-06-02), designer-scraping accusation (2026-09-27).
- Loved: Live Activity ("I love the live activity tracking for projects I'm working on", 2026-11-11), repeats on the row counter, Watch counter, project and stash in one place.
- Begging for: widget ("hate that I have to unlock my phone to use it", 2024-06-24), lock-screen timer stop (2026-02-23), working database, reminders on increase/buttonhole rows ("did a poor job of reminding me", 2026-05-30).

### Knitandnote (57 reviews, 2023-01-24 to 2026-11-05; 21 one-star, 10 two, 10 three, 9 four, 7 five)
- Top complaints: the paywall on features that used to be free (23 of 31 low reviews are money), price, bugs (lost counters, cut-off patterns after an update), poor support, lack of size inclusion.
- Loved: design ("most aesthetically pleasing knitting companion I've seen", 2026-01-26, from a 2-star review); knit-first focus ("downloaded it specifically because I read this app is for KNITTERS", 2023-02-28); pattern library, stash stats.
- Cancel / 1-star triggers:
  - "Now I can't make changes without paying $107 a year." (2026-01-06)
  - "It feels like a bait and switch." (2025-12-09)
  - "would've responded more to a freemium model" (2026-08-20)
  - Years of stash data held hostage (2025-10-07).
  - Size inclusion: a Kickstarter backer with a 47 in bust counted that only 23 of 120 women's garment patterns had her size and wrote "Size inclusivity was clearly not a priority" (2024-01-20).
- Begging for: "buy patterns individually in the app instead of subscribing" (2026-01-04), yarn weight shown on the pattern page, widget for the stitch counter (2023-12-31).

### Ravit (150 reviews, 2018-01-13 to 2026-11-06; 15 one-star, 14 two, 25 three, 19 four, 77 five)
- Top complaints: Ravelry login drops (66 of 150 mention Ravelry), 404 errors on saving patterns, update regressions, outdated look, billing complaint ("Tried to pull money from my account without an active subscription", 2025-12-11).
- Loved: a friendlier way to use Ravelry; one-time $4.99 price.
- Read-across for Ravel: Ravelry users are a large, loyal, mobile-starved group; a one-time $4.99 app holds 4.83 on 6,093 ratings.

### kntd:discover (101 reviews, 2021-12-01 to 2026-09-04; 21 one-star, 9 two, 17 three, 7 four, 47 five)
- Top complaints: ads (23 mentions; "there's an ad every two clicks", 2025-10-21), AI-generated art in the app's own onboarding (7), login failures, update regressions.
- AI art reaction is immediate: "Deleted this app the second I opened it the first time" after seeing the AI art (2025-12-28); "WHY THE USE OF AI GENERATED SLOP?!?" (2025-03-06).

### LoopCraft (113 reviews, 2025-11-02 to 2026-11-09; 29 one-star, 7 two, 12 three, 11 four, 54 five)
- Complaints: paywall after 3 projects, price ("This pricing is INSANE.", 2026-03-21), not beginner friendly, missing videos, billing that continues after cancelling (2026-03-11), derivative-work accusation ("creates a derivative work from a designer and strips out all links", 2026-10-11).

### Tin Can Knits (51 reviews, 2023-06-22 to 2026-09-23; 15 one-star, 4 two, 5 three, 3 four, 24 five)
- Loved: per-size view ("it only shows you the size you're knitting", 2025-04-16), 10+ free patterns for a first sweater (2026-01-05), abbreviations explained in the step.
- Cancel / 1-star triggers: a 2026 update (11 of 19 low reviews): "wipe out all my progress on patterns that I purchased" (2026-04-30), per-size view mostly removed (2026-01-25), row counting removed; needs internet and an account ("App is unusable without making an account", 2026-07-16; "It's internet dependent.", 2026-01-13); free pattern links broken (2026-04-19).
- Begging for: offline use, saved progress ("I'd happily pay for a premium for this app", 2026-02-23, if progress saved), check-off of steps.

### Smaller, still informative
- **KnitsThatFit (23 reviews)**: 12 one-star. The failure mode of a generator: "told me I need 401 yards of yarn for a men's sweater" and "cast on 24 stitches for the back" (2024-11-09); counter lost its place after leaving the app (2026-08-31); app crashes on saved patterns (2023-09-02, 2024-01-27); premium bought but features missing (2023-03-21).
- **Pocket Knitting (12 reviews, 4.89)**: loves PDF notes and counters; sync is paid and "keeps freezing at 54%" (2026-08-08); wants Watch and widget (2026-04-03).
- **Stash2Go II (32 reviews)**: Ravelry client; many 1-stars about blank screens and broken search, premium OCR not working (2026-08-26).
- **StashBot (35 reviews, 4.76)**: a $4.99 yarn-quantity calculator; people value "how much yarn do I need" help (2025-12-30 review).
- **Knitting Genius (16 reviews)**: the nearest idea to Ravel's library ("pattern will adapt"); an update wiped accounts and created patterns (2024-11-07); phone zoom slider ruined the PDF view (2021-01-27).

---

## (d) Knitter attitudes to AI and generated patterns

Evidence level: app reviews are first hand; platform policies and articles are first hand; Reddit points come from search summaries of mirror pages (not read directly).

**Sentiment is hostile, fresh and getting more formal.**
- Etsy, 2026-10-22: bans AI-generated "functional instructions" including knitting and crochet patterns; photo rules tightened 2026-11-07; proactive enforcement planned early 2027; AI-generated artwork is still allowed if disclosed. Etsy previously allowed disclosed AI works, so this is a reversal inside three weeks of today.
- Ribblr, 2026-05-06: "Ribblr says NO to AI patterns." It says it removed over 100 AI patterns in 2026 and acts on reports within 72 hours. Its App Store tagline is "Real makers. Zero slop."
- Ravelry: no published policy; reported to remove obviously AI patterns (Plagiarism Today, 2025-11-24). Several knitters say they trust Ravelry because it is human-moderated.
- r/crochet (via search summary) bans generated imagery and written patterns; an r/knitting thread titled "Anybody else sick of seeing AI generated knitting and crocheting?" ran in June 2024.
- Kate Davies (designer, 2026-04-29) calls AI knitting content "bullshit" in the Frankfurt sense and readers in her comments report nonsense patterns.
- NBC News (2024): buyers on Etsy reported "The pattern looks nothing like the picture that advertised the pattern."

**Specific failure modes knitters and testers cite**
1. Stitch counts that do not add up. A ChatGPT sock test: it said to decrease 66 to 60 with "K4, P2tog" across the round, which removes 11 stitches, not 6 (jaggedlines Substack). Cuff stitch counts reversed when the tester pushed back.
2. Internal inconsistency: 3 needles in one place, 4 in another, gusset and toe on different setups.
3. Charts misread: width of the chart mistaken for rows in the repeat.
4. Invented abbreviations and repeated rows; "rows that repeat" (search summary of tester blogs).
5. Photos that are not of a real knitted object: "impossibly perfect" images, extra fingers, hands that look wrong, soft focus, wrong item. Knitters use image tells and shop age to spot fakes (knithacker, 2026-04).
6. Instructions that are too short for the design, generic five-star reviews, no buyer project photos.
7. Patterns that do not match the sample: "didn't look anything like the image" (YarnPal, 2026-10-27).
8. AI voice narration that mispronounces craft terms (YarnPal, 2026-09-26).
9. Scraping and derivative work: Loopsy (2026-09-22), LoopCraft (2026-10-11) and YarnBuddy (2026-09-27) reviewers accuse apps of stripping designers' links.

**What knitters do accept** (inference from the same sources): calculators and spreadsheets for alterations are treated as legitimate ("calculators or spreadsheets for custom alterations", a Substack writer arguing against whole-pattern AI generation). CustomFit (a computed, human-designed custom pattern) has a long, positive record on blogs. The line is: human design plus verified arithmetic is good; text generated by a language model is not.

**Implications for Ravel**
- Ravel is on the right side of the line technically (deterministic engines, `PatternTests` across every size and yarn weight), but it currently asserts nothing about it publicly. Do not use the words "AI", "smart" or "magic" anywhere. Say "calculated", "worked out from your gauge".
- The Ravel AGENTS rule "patterns carry no designer name" is correct (no invented people), but a faceless library with generic names is what a skeptical knitter reads as a scam shop. Show the real maker and the real method.
- Any AI-made imagery in screenshots or onboarding will be punished immediately (kntd:discover reviews). Ravel draws its own icon and fabric, which is an asset.
- Show the math: a "stitches on the needles" number after every step, and a visible check that it matches the previous step, is the visible proof knitters ask for.

---

## (e) Pricing benchmarks

**Apps (US, from listing pages and reviews)**

| App | Monthly | Yearly | One-time / lifetime | Trial | Notes |
|---|---|---|---|---|---|
| Ravel (planned) | $6.99 | $39.99 | $79.99 | 7 days on monthly and yearly | Tracker, PDFs, stash free |
| YarnPal | about $3.99 (unclear) | $39.99 | none seen | yes (reviewers cite free trial) | A reviewer says $4/week or $40/yr; page also lists $29.99 and $49.99 |
| Loopsy | $4.99 listed, period unknown | $39.99 (per reviewers) | none clear | 7 days, cannot be skipped | Lists $1.99 first month, $9.99, $19.99, $29.99, $99.99 |
| Knit&Note | $9.99 ($8.90 shop page) | $107.99 | none | trial offered (per a reviewer) | 1,200 to 1,400 patterns |
| knitCompanion | n/a | $29.99 "Essentials" | none | free tier | Renewal described as semi-annual by a user |
| My Row Counter | $2.99 | $9.99 to $14.99 | none | trial exists | Sync is premium; ads removable $2.99 |
| YarnBuddy | $1.99 | $14.99 | $44.99 | free up to 10 projects | |
| Pocket Knitting | n/a | n/a | Pro $5.99 / $8.99 | | Cloud $1.99 to $19.99 |
| Tin Can Knits | n/a | n/a | Unlimited projects $36; patterns $6 to $9; collection $20 | 30+ free patterns | In-app per-pattern model |
| KnitsThatFit | n/a | n/a | Premium $14.99; add-ons $0.99 to $2.99 | free tier | |
| Ravit | n/a | n/a | $4.99 | none | 4.83 on 6,093 |
| StashBot | n/a | n/a | $4.99 | none | |
| kntd:discover | $2.29 | $6.49 | n/a | | Ad removal only |
| Ribblr | | | per-pattern | | Free with ad-earned gems |

**Single paid patterns (outside the app)**
- Ravelry/indie sweaters in the sample cluster at $9 to $10 (Fibre Co $10, Payhip starter sweater $9, Ravelry multi-size sweater $9.99).
- Purl Soho PDFs about $9.80 (some $8.80); Brooklyn Tweed single patterns $12 to $15, accessories as low as $4; Brooklyn Tweed bundles about $33 to $41.
- CustomFit (Amy Herzog): $9.99 per custom basic pattern, $12.50 per "design", per the Ravelry listing (marked discontinued/no longer online there, so confirm on the live site); an optional subscription of monthly pattern generations was described at about $5 per month for 8 patterns per year on a mirror page (unverified).
- Etsy crochet/knit patterns: typically $2 to $10 (NBC, 2024).
- No verified Ravelry median price was found. Treat $4 to $10 as the working range for non-garment patterns and $9 to $15 for sweaters.
- Hats and scarves are among the most abundant free patterns online (Tin Can Knits, Purl Soho and thousands on Ravelry; the free filter returns hundreds of thousands of patterns).

**Survey (Germany, July 2025, n=1,004, crazypatterns.net)**: about half prefer free patterns; almost half have bought at least one paid pattern; four in ten mostly use free resources and occasionally buy; top purchase drivers: clear step-by-step instructions, distinctive designs, learning less common techniques, overall quality. Handmade gifts motivate 68%. (Germany only; use as direction.)

**Subscription benchmarks (RevenueCat, State of Subscription Apps 2026, via secondary summaries)**: hard-paywall median trial-to-paid 10.7% vs 2.1% for freemium; non-AI apps split 41.8% yearly, 30.3% weekly, 26.2% monthly; reported first-year cancellation of annual plans rose from about 56% to about 72%. Ravel is freemium, so expect the low end of trial conversion; the free tracker is the acquisition engine.

**Framing $39.99/yr**
- It equals 4 to 5 single multi-size patterns at $9 to $10, or one sweater pattern plus a hat at Brooklyn Tweed prices. It is the same price as the two biggest competitors and well under Knit&Note's $107.99.
- But Ravel's library is 20 mostly simple designs, versus 1,200 to 1,400 at Knit&Note. Only the raglan pullover is priced like something knitters pay $9 to $15 for. For a one-sweater year, the $6.99 monthly (one month) is cheaper than buying that pattern; for gift season it is cheap.
- A subscription to a pattern library has precedent (Knit&Note, YarnPal, Loopsy, Ribblr, CustomFit), but each of the reviews that mention it also asks for per-pattern options or objects to the price. There is no precedent in this set for a $79.99 lifetime; the highest lifetime seen is YarnBuddy's $44.99, Tin Can Knits' $36 unlimited projects.

---

## (f) Segments

| Segment | Size signal | What they need from a tracker | What they need from sized patterns | Pay behavior and risk |
|---|---|---|---|---|
| Beginner, first scarf or hat (including teens and kids) | Biggest download pool: YarnPal and Loopsy reviewers are mostly beginners, some 9 to 11 years old; "beginner/video/tutorial" appears in 46 of 150 YarnPal reviews | Giant tap target, one project, no setup, no account, no ads | Child/adult sizes by name, yarn amount, abbreviation help in the step, stitch videos | Will not pay and writes 1-star reviews about paywalls ("my moms paying for that", 2026-09-22). Value: downloads and rating volume, not revenue. Free patterns must be genuinely usable |
| Intermediate sweater knitter | Core payer; uses Ravelry, buys $9 to $15 patterns | Multiple counters, repeats, chart/PDF markup, notes on rows, no lost progress | Real fit across sizes (bust over 50 in), gauge-driven math, yardage, schematics | Will pay for fit and trust. Hates wrong math, hates paywalled basics. Needs more than one sweater to subscribe |
| Returning knitter | Common in reviews ("after having a baby", 2025-10-24; "back into knitting", 2026-04-19) | Pick up where they left off; stash import; easy restart | Refresher, abbreviations, familiar classics | Pays if the app is stable; hurt most by features that change after update |
| Gift knitter (seasonal) | About 80% of respondents in the 2022 Craft Yarn Council report gift handmade items; Loopsy reviews: "starting to make Christmas presents" (2026-09-29) | Quick start, deadline progress, Watch/lock-screen counting | Hat/cowl/blanket by recipient size (baby, child, adult), yardage | Best fit for the $6.99 monthly or one-off unlock; churn after December. Window is now to mid-December |
| Crocheter | Large: crochet appears in 53 of 150 YarnPal, 57 of 150 Ribblr, 30 of 150 My Row Counter reviews | Counter works the same for rounds; hooks in stash | Crochet patterns (not offered by Ravel) | Will ask for crochet; knit-first users explicitly value knit-focused apps ("for KNITTERS", 2023-02-28), and one YarnPal reviewer felt misled by "crochet AND knitting" marketing (2026-09-21) |
| PDF power user | knitCompanion, Pocket Knitting, My Row Counter audiences | Import any PDF, highlights, repeat counters, Watch, sync | Not the target for the library | Will pay $10 to $30/yr for tracker features if the free tier is solid; Ravel gives PDF reading free, so little to charge here |

---

## (g) FINDINGS for Ravel

Ranked by expected effect on downloads, trial starts and ratings. "[wrong path]" marks places where Ravel's current direction runs against the evidence.

### R-01 | trust | P0 | State plainly that the patterns are calculated, tested and not AI-written, and remove anything that sounds like AI [wrong path]
Evidence: Etsy bans AI-generated knitting and crochet patterns (2026-10-22) and Ribblr advertises "Real makers. Zero slop." YarnPal draws "This app is all AI slop." (2026-10-25) in 26 of its 71 latest low ratings. kntd:discover users delete the app on seeing AI art (2025-12-28). KnitsThatFit gets mocked when a generator outputs impossible counts (401 yards then "cast on 24 stitches", 2024-11-09). Ravel's store copy says patterns "write themselves", names no human and does not explain the method.
Recommendation: Add one plain statement in the description, subtitle area and paywall: "Every number is calculated from your gauge and checked, no AI writing." Never use "AI", "smart" or "magic". Put the proof on screen: after each step show the stitch count and, in the pattern header, "stitches checked at every size". Tell the real story of who made it (only true facts, no invented bios). Keep screenshots and icon free of generated imagery.

### R-02 | pricing | P0 | The paid offer must be built around fit-critical garments, and offer a per-pattern option alongside the subscription [wrong path]
Evidence: 18 of 20 designs are hats, scarves, cowls, blankets and accessories that thousands of free patterns already cover (Tin Can Knits, Purl Soho, Ravelry free filter). Only the raglan pullover resembles what knitters pay $9 to $15 for. Knit&Note users ask for exactly this: "buy patterns individually in the app instead of subscribing" (2026-01-04); Tin Can Knits sells single patterns at $6 to $9 inside its app; CustomFit sells $9.99 per custom pattern. Comparable subscriptions offer 1,200 to 1,400 patterns (Knit&Note) or heavy video libraries (YarnPal); Ravel's offer is 20 simple designs for $39.99.
Recommendation: Lead the paywall with the sweater and the fit story (sizes to a 66 in chest). Add a single-pattern unlock for the raglan (test $6.99 to $9.99) next to the subscription so a one-sweater knitter is not forced into a plan. Keep the two free designs, and consider making one more beginner design free (Tin Can Knits wins goodwill with 10+ free patterns).

### R-03 | positioning | P0 | Lead the listing with the proof points no competitor can claim: free tracker, no account, no ads, works offline, frozen patterns
Evidence: Competitor 1-stars: "Not free" and "false advertising" (Loopsy 23 of 150, YarnPal 16 of 150), "Make all features free again!" (My Row Counter, 2026-09-06), ads (kntd 23 of 101, YarnPal 19 of 150), account walls ("App is unusable without making an account", Tin Can Knits, 2026-07-16), internet dependence (Tin Can Knits). Updates changing saved content cause review bombs (Loopsy 2026-09-24 to 2026-10-09; Tin Can Knits 11 of 19 low). Ravel already meets all of these and the description only says "FREE, FOR GOOD" and one buried sentence about cast-on patterns staying put. The subtitle is nearly Loopsy's.
Recommendation: Rewrite subtitle and first screenshot lines around: "Free row counter. No account. No ads. Works offline." and "Your pattern never changes after you cast on." Differentiate the subtitle from Loopsy's. Make sure every claim is literally true (Loopsy's "free forever" plus a forced trial is exactly what got it 1-starred).

### R-04 | trust | P1 | Make the trial and billing impossible to misread, and add a trial reminder
Evidence: Billing and trial complaints are the largest 1-star bucket at the top two competitors: "They literally don't let you opt out of the free trial" (Loopsy 2026-09-22), "charged the $43 and then refused to refund" (2026-11-09), "my $44 was still taken" (YarnPal, 2026-11-12), a reviewer who "forgot to cancel" (Loopsy, 2026-10-10). One reviewer noted no reminder before the charge. Knitters take weeks per project, so a 7-day trial ends before most patterns are finished.
Recommendation: Keep the library the only gated area (already true) and never force a trial. On the paywall show the price, the date billing starts and "Cancel any time in Settings" with a direct Manage Subscription link. Offer an opt-in local notification on day 5 ("Your trial ends tomorrow"). Consider a longer trial for the yearly plan (test 14 days). Put refund help text in the support page (refunds are Apple's, and Loopsy's reviewers blamed the developer for it).

### R-05 | feature-gap | P1 | Add free iCloud backup/sync and an export, because the data is local-only [wrong path]
Evidence: Sync/backup/lost-data complaints: YarnBuddy 33 of 150, Loopsy 16, knitCompanion 15, My Row Counter 10 (sells "Restore Backup" at $9.99). Examples: "getting a new phone and losing all of my inventory and projects" (Loopsy, 2026-10-09); "lost track of the several rows I had knitted" (knitCompanion, 2025-09-07); "Lost PDFs and projects!" (2024-01-23). Pocket Knitting and My Row Counter paywall sync, which angers users. Ravel is SwiftData local only, with no CloudKit, iCloud container or export in the code.
Recommendation: Add private iCloud sync (no Ravel account needed) as a free feature, plus a one-tap export of projects and counts. This is an advantage over the paid-sync competitors and fits "a row count must never be lost". Caution: SwiftData sync requires optional/defaulted model fields and a frozen-plan blob check, so test migration on real data before shipping.

### R-06 | feature-gap | P1 | Count rows without unlocking the phone: lock-screen widget, Live Activity and Apple Watch
Evidence: YarnBuddy reviewers: "I love the live activity tracking for projects I'm working on" (2026-11-11), "hate that I have to unlock my phone to use it" (2024-06-24). Loopsy: "I love the row counter widget on my phone lock screen" (2026-10-09). My Row Counter: Watch counting is the favorite feature (2026-10-21). Requests for Watch from knitCompanion (2024-01-14, 2024-07-16) and Pocket Knitting (2026-04-03). Watch sync is also a top complaint when it is unreliable (YarnBuddy 2025-02-01, 2026-02-02). Ravel has none of these (haptics and keep-awake exist).
Recommendation: Ship a lock-screen / Dynamic Island Live Activity with a +1 / -1 button first (App Intents), then a Watch counter. Reliability matters more than breadth: a Watch that drops taps is punished.

### R-07 | product | P1 | Add a second and third fit-critical design (cardigan or child sweater, socks or mittens) before leaning on the subscription
Evidence: Knit&Note buyer with a 47 in bust found only 23 of 120 women's garment patterns had her size and called it a lack of priority (2024-01-20). Tin Can Knits' "only your size" view is the thing users praise and miss. Ravelry plus-size filtering reportedly drops results from about 13,000 to about 1,300 (secondary source). Ravel's raglan covers XS to 5X (chest 32 to 64 in; range to 66) which is rare, but there is exactly one such design, no cardigan, no child or baby sweater, no socks. Gift knitters (about 80% in the 2022 CYC report) make baby and child items.
Recommendation: Rank new designs by fit risk and gift demand: child/baby sweater, cardigan (same engine), socks or mittens. Advertise the size range as a feature ("fits to a 66 inch chest"). Keep the Trending shelf, but do not spend design time on more accessories until a second garment exists.

### R-08 | feature-gap | P1 | Put abbreviation and stitch help inside each step for beginners
Evidence: Beginner/video/tutorial terms appear in 46 of 150 YarnPal and 27 of 113 LoopCraft reviews; complaints include "Not for beginners" (2026-10-16) and no explanation of a magic ring (2026-06-08). Tin Can Knits users praise help "right in the step" and miss it after the update (2026-01-14). Ravel has no tutorials or glossary, and the beginner segment generates the most downloads and ratings.
Recommendation: Tap a term in a step ("k2tog", "yo") to open a one-screen explanation with a short looped illustration (text-only is fine at first). Do not build a video library; link the glossary from the free designs so the free tier is usable on day one.

### R-09 | feature-gap | P2 | Lean on guided "next instruction" as the pay trigger, and bring light guidance to imported PDFs
Evidence: Loopsy's removed Smart Pattern ("turned a pdf pattern into workable steps", 2026-09-26) was the stated reason people bought annual plans. Ribblr fans like ticking off steps (2026-10-28). My Row Counter reviewers like notes that pop at certain rows (2026-10-24) and ask for auto-created secondary counters (2026-10-28). YarnBuddy users complain it missed a buttonhole or increase row (2026-05-30). Ravel's guided mode exists only for its own library.
Recommendation: In the paywall and screenshots, show the guided step with the live stitch count as the benefit. Cheap free addition: notes/reminders attached to specific rows of any project (a popup at row N), which covers the buttonhole complaint without a PDF parser.

### R-10 | pricing | P2 | Re-test the price ladder: keep $39.99 yearly, reconsider $6.99 monthly and $79.99 lifetime
Evidence: Yearly parity with YarnPal and Loopsy ($39.99) is safe. Monthly benchmarks: YarnBuddy $1.99, My Row Counter $2.99, kntd $2.29, Loopsy $4.99; only Knit&Note ($9.99) is higher. Lifetime: highest observed elsewhere is $44.99 (YarnBuddy). Annual retention data is poor industry-wide (95% of cancelled annual subscribers never return). A lifetime also obliges a growing library and Loopsy shows the cost of removing features later.
Recommendation: Hold $39.99. Test $4.99 to $5.99 monthly for the gift window and a $49.99 to $59.99 lifetime. If the single-pattern unlock (R-02) ships, make lifetime the "I knit a lot" option. Treat these as A/B tests, not facts; the evidence is competitor list prices, not conversion data.

### R-11 | feature-gap | P2 | Register as a PDF handler and make "Open in Ravel" work
Evidence: knitCompanion users complain "open with" does not list the app (2024-01-13) and PDF import is hard; Loopsy users can't import from sites and ask for an app that "would strip all the ads and photos off the pattern website" (2026-10-18); My Row Counter fans praise website and PDF import (2026-11-10). Ravel imports only through an in-app file picker (PDF or images), with no document types in Info.plist.
Recommendation: Declare PDF as a supported document type so Safari, Files and Ravelry downloads can "Open in Ravel". Add a share-sheet action for photos. Skip web-page scraping: LoopCraft, Loopsy and YarnBuddy are being accused of stealing from designers.

### R-12 | positioning | P2 | Stay knit-first, keep the counter crochet-friendly, and do not build crochet patterns yet
Evidence: Crochet dominates the competitor reviews (53 of 150 YarnPal, 57 of 150 Ribblr, 30 of 150 My Row Counter), and crocheters will ask for it. But knitters value knit-first apps ("downloaded it specifically because I read this app is for KNITTERS", Knit&Note 2023-02-28); a YarnPal reviewer felt misled by "crochet AND knitting" marketing (2026-09-21); crochet reviewers want videos, which Ravel does not have. The Ravel name and keywords are knit-led and the stash already has hooks.
Recommendation: Say "knit and crochet row counter" in the free tracker description and keywords, keep "Knitting Patterns" for the library, and answer crochet pattern requests with "not yet". Revisit after launch based on review requests.

### R-13 | feature-gap | P2 | Ask for the rating at a happy, early moment, not only after a project is finished
Evidence: My Row Counter's latest 150 reviews are 141 five-star over 5.5 months (2026-05-31 to 2026-11-11), a sign of in-flow prompting; YarnPal's latest 150 are 31% five-star because its unhappy users are the vocal ones. Ravel's `ReviewPrompt` fires only 3 seconds after a project is marked finished, from the second launch, 30-day cooldown. Projects take weeks, so few users will ever see it. This is an inference from competitor patterns, not a measured result.
Recommendation: Add a second trigger after a milestone (for example the 100th counted row across three sessions), keep the cooldown, and never prompt on the paywall or after a failure. Ratings drive search ranking in a market with many near-identical new counters.

### R-14 | positioning | P2 | Use the gift-season window now
Evidence: The CYC 2022 report found nearly 80% knit or crochet for gifts, led by blankets, scarves and hats. Reviews at Loopsy mention starting Christmas presents (2026-09-29, 2025-12-02). Ravel's Trending list already tags "Gift season" items (ribbed beanie, handwarmers, balaclava, neck scarf). Today is 2026-11-13, and a hat or cowl takes days.
Recommendation: Put gift hats, cowls and baby blankets first in screenshots and the promotional text, and make the free two designs the gift-ready ones. Run the 7-day trial during the gift window. Plan a post-December retention message (stash and next project) because monthly subscribers will churn.

### R-15 | trust | P3 | Check the name "Ravel" against Ravelry before launch
Evidence: Ravelry states "There is no official Ravelry app" and every third-party client (Ravit, kntd:discover, Stash2Go, Unraveled, Wooly) carries an "unaffiliated" disclaimer. "Ravel" is a clipped form of "Ravelry" and the store name is "Ravel: Knitting Patterns". I found no evidence of a dispute or of user confusion, and the name is not otherwise taken on the US App Store, so this is a precaution, not a finding of harm.
Recommendation: Do a quick trademark and App Review risk check, avoid the word "Ravelry" in the store copy except in an unaffiliated disclaimer if import is ever added, and keep the support page ready for "is this Ravelry?" questions.

### R-16 | positioning | P3 | Do not lead with the growing-fabric visual; lead with function [wrong path]
Evidence: Across 1,502 reviews no one asks for a visual progress display. Praise for design appears rarely, and in the same breath as pricing complaints (Knit&Note: "the most aesthetically pleasing knitting companion I've seen" but "not worth the subscription price", 2026-01-26). A top-rated counter reviewer writes "I don't need my tools to be pretty." (My Row Counter, 2026-10-28). What people ask for is reliability, sync, widgets, free basics and trust.
Recommendation: Keep the fabric (it is distinctive and costs nothing to keep) but put it second in screenshots, after the free tracker, the guided step and the size range. Test it in a screenshot A/B before treating it as the headline.

---

## Sources

App data: iTunes Search and Lookup API (country=us), iTunes RSS customer reviews feed for ids 6738537088, 6745416564, 1058142783, 1342608792, 1529605339, 1267678125, 1634163608, 1234214894, 1572271760, 6752294439, 6444720146, 1553071325, 1463278276, 928131718, 1182812124, 1051125077, 1318598164, 6749139586, 1601194384. App Store pages for IAP lists: apps.apple.com/us/app/ for ids 6738537088, 6745416564, 1634163608, 1058142783, 1342608792, 1529605339, 1267678125, 1572271760, 1234214894, 6444720146, 1182812124, 1553071325, 1463278276, 928131718.

External:
- Etsy AI pattern ban: https://www.valueaddedresource.net/etsy-bans-ai-patterns/
- Ribblr on AI patterns: https://meet.ribblr.com/t/a-message-from-me-about-ai-patterns/724441
- Plagiarism Today, "The AI Invasion of Knitting and Crochet": https://www.plagiarismtoday.com/2025/11/24/the-ai-invasion-of-knitting-and-crochet/
- NBC News on AI crochet listings: https://www.nbcnews.com/tech/tech-news/etsy-crochet-buyers-suspect-ai-made-images-used-sell-patterns-rcna145878
- Knit Hacker on spotting fake patterns: https://knithacker.com/2026/04/trusting-your-spidey-sense-how-i-spot-fake-ai-generated-patterns-shops/
- Kate Davies on AI: https://katedaviesdesigns.com/2026/04/29/knitting-bullshit/
- ChatGPT sock test: https://jaggedlines.substack.com/p/chatgpt-knits-a-sock
- r/knitting AI thread (title only, via search result): https://redlib.ssps.io/r/knitting/comments/1dgr4we/anybody_else_sick_of_seeing_ai_generated_knitting
- Ravelry on third-party apps: https://www.ravelry.com/about/apps
- CustomFit on Ravelry: https://www.ravelry.com/patterns/library/customfit
- Knitting Help forum row counter thread: https://forum.knittinghelp.com/t/row-counter-for-smart-devices/133970
- Germany survey: https://www.crazypatterns.net/en/knit-crochet-survey-2025
- RevenueCat benchmarks (secondary summaries): https://www-docs.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026 and https://ppc.land/ai-apps-earn-41-more-per-user-but-churn-30-faster-revenuecat-finds/
- Craft Yarn Council 2022 report: https://prnewswire.com/news-releases/craft-yarn-council-cyc-releases-2022-consumer-insights-into-craft-yarn-purchases-report-301758679.html
- Plus-size knitting context: https://tildes.net/~hobbies/vn4/the_plus_size_knitters_who_are_solving_an_inclusivity_problem
