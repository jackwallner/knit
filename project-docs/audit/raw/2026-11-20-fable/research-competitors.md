# Ravel vs what knitters already use: feature gaps, reviews, pricing, 2026 changes

Researched 2026-11-20, US App Store and US Google Play. Read-only: no app code changed, nothing bought, no account created. This builds on `project-docs/audit/raw/research-competitors.md` (2026-11-13, "the earlier report") and does not repeat its AI-backlash and segment sections.

## Method and limits (read first)

- **App facts** (rating, rating count, price, last update, devices, Watch support) come from the iTunes Lookup and Search APIs (`https://itunes.apple.com/lookup?id=<id>&country=us`) and each app's US App Store page (`https://apps.apple.com/us/app/id<id>`), fetched 2026-11-20. Rating counts are lifetime US counts.
- **In-app purchase lists** come from the "In-App Purchases" block of each App Store page. Apple lists prices but not billing periods; where the period is not in the product name, it is marked "period not stated".
- **Feature cells** come from the app's App Store description and its Version History text on the same page, or the developer's own site where linked. "Y" means the listing, notes or site states it. "R" means only reviews say it. "P" means it is paid-tier only. "-" means I found no statement of it; that is not proof the feature is absent. "?" means unclear or conflicting.
- **Reviews**: 2,760 unique US reviews pulled from the iTunes RSS feed (`https://itunes.apple.com/us/rss/customerreviews/page=N/id=<id>/sortby=<mostRecent|mostHelpful>/json`, pages 1 to 10, both sorts) for 11 apps: YarnPal 679, My Row Counter 726, Loopsy 399, knitCompanion 342, YarnBuddy 248, Ribblr 212, LooseLoop 65, Knit&Note 57, CozyKnit 12, Pocket Knitting 12, StitchTally 8. The feed caps out, so windows differ per app. Theme counts are regex hits on title plus body; read them as relative signals, not statistics. Quotes are under 15 words.
- **Android** presence comes from Google Play detail pages (`https://play.google.com/store/apps/details?id=<package>`).
- Reddit and Ravelry forums were not read (the earlier report found they block automated fetches).

---

## 1. Bottom line

Ravel's library is genuinely unlike anything knitters use: no live app computes 45 designs from the knitter's own measurements and gauge, freezes the result per project, and offers a corrected pattern at the row you are on. The tracker side is the problem. Ravel's free tracker is free, offline and account-free, but it is thinner than the free tiers of the apps knitters already run (YarnBuddy, LooseLoop, CozyKnit) and far thinner than what My Row Counter and Loopsy users pay $10 to $40 a year for. A knitter moving a live project into Ravel in week one will notice, in this order: no backup or sync, a PDF reader with one row band and no markup, no way to count without opening the app (widget, Lock Screen, Watch), only two counters with no linked or auto-resetting counter and no row reminders, no Ravelry import, no project timer, and no project photos.

None of these touch the paywall rule (the tracker stays free). The two that most affect ratings are data safety and counting from the Lock Screen or Watch, because they are the exact features competitors' happiest reviewers say they pay for and their angriest reviewers say they lost.

---

## 2. Feature matrix

### 2a. App facts (US, 2026-11-20)

| App | App Store link | Rating | US ratings | Price model (IAP list) | Last update | Watch app | Android (Play rating, installs) |
|---|---|---|---|---|---|---|---|
| **Ravel** | (pre-launch) | n/a | n/a | Free tracker; library $6.99/mo, $39.99/yr (7-day trial each), $79.99 lifetime | n/a | No | No |
| YarnPal | [id6738537088](https://apps.apple.com/us/app/id6738537088) | 4.71 | 35,478 | Free; "Yarnpal/Knitpal Premium" $3.99 to $49.99 | 2026-11-09 | No | Yes ([com.yarnpal.ai](https://play.google.com/store/apps/details?id=com.yarnpal.ai)) |
| Loopsy | [id6745416564](https://apps.apple.com/us/app/id6745416564) | 4.75 | 17,196 | Free; "Loopsy Pro" $4.99, $9.99, $19.99, $29.99, $39.99, $49.99, $99.99 | 2026-11-18 | Yes | No ("Join Android waitlist", [loopsy.com](https://loopsy.com)) |
| knitCompanion | [id1058142783](https://apps.apple.com/us/app/id1058142783) | 4.83 | 6,929 | Free Basics; "Setup + Essentials" / "Essentials" $29.99 (annual, [knitcompanion.com](https://www.knitcompanion.com)) | 2025-12-15 | No | Yes ([3.48 on 965](https://play.google.com/store/apps/details?id=com.create2thrive.knitcompanion)) |
| Ravit (Ravelry client) | [id1234214894](https://apps.apple.com/us/app/id1234214894) | 4.83 | 6,116 | $4.99 paid, no IAP | 2026-07-24 | No | Yes ([Ravit](https://play.google.com/store/apps/details?id=com.enhancient.android.ravit)) |
| LoopCraft | [id6752294439](https://apps.apple.com/us/app/id6752294439) | 4.70 | 5,685 | Free; $3.99 weekly, $29.99 to $49.99 yearly | 2026-11-13 | No | not checked |
| kntd:discover (Ravelry client) | [id1572271760](https://apps.apple.com/us/app/id1572271760) | 4.79 | 5,257 | Free with ads; AdFree $6.49/yr, $2.29/mo | 2026-11-02 | No | Yes ([kntd](https://play.google.com/store/apps/details?id=com.samaitch.kntd)) |
| My Row Counter (Annapurnapp) | [id1342608792](https://apps.apple.com/us/app/id1342608792) | 4.84 | 4,005 | Free; Premium $2.99/mo, $9.99 to $14.99/yr; "Restore Backup" $9.99; "No Ads" $2.99 | 2026-10-28 | Yes (Premium) | Yes ([4.87 on 15,928, 1M+](https://play.google.com/store/apps/details?id=com.row_counter)) |
| Knitting Chart | [id1251317736](https://apps.apple.com/us/app/id1251317736) | 4.35 | 1,313 | Free | 2023-01-18 | Yes | not checked |
| Crochet Patterns - Row Counter | [id1545599414](https://apps.apple.com/us/app/id1545599414) | 4.66 | 1,216 | Free; $1.49 to $4.99/mo, $17.99 to $29.99/yr, $39.99 lifetime | 2026-10-27 | Yes | not checked |
| YarnBuddy | [id1267678125](https://apps.apple.com/us/app/id1267678125) | 4.46 | 807 | Free up to 10 projects; Pro $1.99/mo, $14.99/yr, $44.99 "No Expiration" | 2026-11-15 | Yes | Not found on Play |
| Ribblr | [id1529605339](https://apps.apple.com/us/app/id1529605339) | 4.25 | 602 | Free; no App Store IAP listed; per-pattern sales, ad-earned "Gems" | 2026-10-28 | No | Yes ([4.61 on 4,139](https://play.google.com/store/apps/details?id=com.ribblr.app)) |
| StitchTally | [id6738016114](https://apps.apple.com/us/app/id6738016114) | 4.84 | 311 | Free; $0.99/wk, $1.99/mo, $9.99/yr, $24.99 lifetime | 2026-11-10 | Yes | Same-name Play app is by a different developer; treat as no |
| LooseLoop | [id6756404492](https://apps.apple.com/us/app/id6756404492) | 4.58 | 309 | Free; Premium $4.99, $24.99 "Founding Member", $49.99, $99.99 (periods not stated); AI parser credits $9.99 to $19.99 | 2026-11-10 | Yes | Yes ([4.48 on 443](https://play.google.com/store/apps/details?id=com.looseloop.app)) |
| Woolsy (new 2026) | [id6759599166](https://apps.apple.com/us/app/id6759599166) | 4.59 | 231 | Free; $3.99/wk, $8.99/mo, $19.99 to $39.99/yr | 2026-11-18 | No | not checked |
| Knitandnote (Knit&Note) | [id1634163608](https://apps.apple.com/us/app/id1634163608) | 3.93 | 194 | Free; "Premium" $107.99, $14.99, $11.90 (periods not stated) | 2026-11-18 | No | Yes ([3.45 on 331](https://play.google.com/store/apps/details?id=com.knitandnote.android)) |
| Tin Can Knits | [id6444720146](https://apps.apple.com/us/app/id6444720146) | 4.08 | 138 | Free; single patterns $6 to $9, "Unlimited projects" $36, collection $28 | 2026-11-19 | No | ? (a Play app "Tin Can" exists, [app.tincan](https://play.google.com/store/apps/details?id=app.tincan); not confirmed as the same) |
| KnitsThatFit Sweaters | [id1182812124](https://apps.apple.com/us/app/id1182812124) | 4.33 | 127 | Free; Premium $14.99, PDF $2.99, Schematic $2.99 | 2025-03-31 | No | not checked |
| Pocket Knitting | [id1553071325](https://apps.apple.com/us/app/id1553071325) | 4.89 | 121 | Free; Pro $5.99 / $8.99; Cloud storage $1.99 / $19.99 | 2026-09-24 | No | Yes ([4.86 on 600](https://play.google.com/store/apps/details?id=com.rfsp.pocketknitting)) |
| Knitrino | [id1495475758](https://apps.apple.com/us/app/id1495475758) | 4.37 | 111 | Free app; sells yarn kits (no App Store IAP listed) | 2026-10-12 | No | Yes ([com.com.knitrino](https://play.google.com/store/apps/details?id=com.com.knitrino)) |
| CozyKnit | [id6755319044](https://apps.apple.com/us/app/id6755319044) | 4.84 | 64 | Free; Pro $3.99/mo, $17.99/yr, $44.99 lifetime | 2026-11-19 | No | not found |
| Cast Along (new 2026) | [id6760704901](https://apps.apple.com/us/app/id6760704901) | 4.96 | 56 | Free, no IAP yet ("When a subscription arrives...") | 2026-11-12 | No | not checked |
| Knitting Genius (Annapurnapp) | [id1318598164](https://apps.apple.com/us/app/id1318598164) | 4.23 | 52 | Free; per-pattern $2.99 (Pullover, Cardigan, Socks...), "All patterns" $4.99, Premium $9.99, sync $7.99/yr per description | 2026-11-08 | Yes | Yes ([com.tricoton](https://play.google.com/store/apps/details?id=com.tricoton)) |
| Stash2Go II (Ravelry client) | [id1463278276](https://apps.apple.com/us/app/id1463278276) | 4.68 | 47 | Free; Premium $29.99; ad removal $1.99/mo, $9.99/yr | 2026-11-12 | Yes (also Apple TV) | Yes ([4.62 on 149](https://play.google.com/store/apps/details?id=com.luxx.Stash2GoII)) |
| Unraveled (Ravelry client, new 2026) | [id6761283301](https://apps.apple.com/us/app/id6761283301) | 4.75 | 32 | 14-day trial, then $7.99 one-time ($9.99 also listed) | 2026-11-19 | No | not checked |
| Stashora (Ravelry client, new 2026) | [id6782335296](https://apps.apple.com/us/app/id6782335296) | 4.45 | 20 | Free; Pro $6.99/mo, $29.99/yr | 2026-11-08 | No | not checked |
| Yarnzy (new 2026) | [id6809693241](https://apps.apple.com/us/app/id6809693241) | 4.72 | 18 | $7.99/wk, $14.99/mo, $29.99 to $49.99/yr, $79.99 / $99.99 lifetime | 2026-11-13 | Yes | not checked |
| Knitflow | [id6740465748](https://apps.apple.com/us/app/id6740465748) | 4.79 | 14 | $2.99 / $4.99 mo, $24.99/yr, $79.99 lifetime | 2026-11-16 | No | not checked |
| Stitch Fiddle Row Tracker | [id6815132635](https://apps.apple.com/us/app/id6815132635) | 4.00 | 7 | Free | 2026-11-10 | No | No |
| KnitHub (new 2026) | [id6769869291](https://apps.apple.com/us/app/id6769869291) | 4.83 | 6 | $1.99/mo, $17.99/yr, $34.99 lifetime | 2026-11-19 | Yes | not checked |

Names in the brief that are not live US iOS competitors:
- **BeeCount**: a free, open-source Android-only counter on F-Droid ([f-droid.org](https://f-droid.org/en/packages/com.knirirr.beecount/)); not on Google Play (Play returns 404 for `com.knirirr.beecount`) and no iOS app found.
- **Popknit**: no app by that name found on the US App Store, Google Play or the web (search returned only Pocket Knitting and KNIT). Unverified whether it exists under another name.
- **Bellish**: the 2020 custom-pattern generator (60,000 iOS downloads by June 2020 per [Blackbird](https://www.blackbird.vc/portfolio/bellish)) no longer appears in US App Store search, and `bellish.co` now 301-redirects to an unrelated gambling-style domain (fetched 2026-11-20). Treat it as defunct. It is the closest past analogue to Ravel's library, and it did not last.
- **LoveCrafts**: no LoveCrafts knitting app found on the US App Store (search returns only unrelated "Lovecraft" games). LoveCrafts still runs its web store ([about page](https://www.lovecrafts.com/en-us/pages/about-lovecrafts)).
- **Stitch Fiddle**: the official Stitch Fiddle is a web chart editor ([stitchfiddle.com](https://www.stitchfiddle.com/en)) and its homepage links no iOS app. The App Store "Stitch Fiddle Row Tracker" is sold by "SHEUNG TAK DISPENSARY LIM" and uses Google Gemini and OpenAI for "smart tools" ([listing](https://apps.apple.com/us/app/id6815132635)); I could not tie it to Stitch Fiddle the company. Unverified, possibly a name-alike.
- **Knitting Buddy / Knitting and Crochet Buddy**: Android, 4.18 on 1,991 ratings, 100K+ installs ([Play](https://play.google.com/store/apps/details?id=androiddeveloperjoe.knittingbuddy)). An unrelated iOS "Knitting Buddy 2" (Colorwork Apps) has 11 ratings ([lookup](https://itunes.apple.com/search?term=knitting%20crochet%20buddy&country=us&entity=software)).
- **Ravelry**: still "There is no official Ravelry app" ([ravelry.com/about/apps](https://www.ravelry.com/about/apps)).

### 2b. Feature matrix: Ravel vs the 12 apps knitters most use for tracking

Sources per column: that app's App Store page (description and Version History) linked in 2a, plus the developer site where noted; "R" cells cite reviews in section 3. Ravel's column is from the repo (`Shared/Models/Models.swift`, `Ravel/Views/ProjectView.swift`, `Ravel/Views/PatternView.swift`, `Ravel/Info.plist`) and the store description.

| Feature | Ravel | Loopsy | YarnBuddy | My Row Counter | knitCompanion | Knit&Note | Pocket Knitting | StitchTally | LooseLoop | CozyKnit | Stash2Go II | Ribblr | YarnPal |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Multiple counters per project | 2 (row count + one second counter) | Y (R: "7 for my typical barefoot socks", [loopsy.com](https://loopsy.com)) | Y unlimited | Y | Y (6 free, more P) | Y | Y | Y | Y | Y | Y | - | Y (claimed) |
| Linked / repeat / auto-reset counters | Repeat position inside the row count only | Y repeats | Y linked + repeating | Partial (R: wants repeat counter, 2026-05-27) | Y linked | ? | Y linked | - | - (R: missing auto-restart counter, 2026-01-31) | Y "smart rules" | Y repeats | - | ? |
| Stitch counter | No (library steps show the stitch total) | Y | ? | Partial (totals) | Y via Magic Markers (P) | ? | ? | - | ? | Y | Y | R (tick off stitches) | Y (claimed) |
| Row reminders / notes at a row | No | ? | Y (P) | Y | Y (P) | ? | ? | - | Y free | Y row-by-row instructions | ? | - | - |
| Pattern PDF import | Y (PDF or photos) | Y (PDF, web, YouTube, Drive, OneDrive) | Y | Y (PDF, web) | Y | Y | Y | - | Y | Y | Y (Ravelry PDFs) | Y (converts PDFs) | Y (AI converter) |
| Place marker in PDF | One horizontal row band | R | Y horizontal + vertical bars free | Y highlighter linked to counter | Y row marker, inverted marker (P custom) | Y highlighters | Y reading line | - | Y | Y bookmarks | ? | - | - |
| Highlight / annotate / draw on PDF | No | R ("annotate on it", 2026) | Y (P) | Y (P) | Y (P) | Y | - | - | - (R wish, 2026-09-11) | Y | ? | - | - |
| Chart support with row ruler | Band works on a chart page; no column marker | Y (claimed) | Y bars | Y (C2C highlighter, chart maker) | Y core (Magic Markers, join charts) | Y | Y (P, "big grid" reader) | - | Y "focused chart row view" | ? | ? | - | - |
| Ravelry login / import | No | Y (incl. queue) | Y PDFs | Y | Y | - | Y | - | ? | Y database lookup | Y full client | - | - |
| Photos per project | No (photos only as pattern pages) | Y | Y | Partial | - | Y | Y | Y | ? | Y | Y | community | - |
| Notes per project | Y (text) | Y | Y (rich notes P) | Y | Y | Y | Y | Y | Y | Y | Y | - | - |
| Project timer | No | Y | Y (P) | Y | Y | Y | Y | - | Y | Y | ? | - | - |
| Home Screen widget | No | Y | Y interactive | ? unverified | - | ? | ? | Y interactive | ? | Y | Y | Y (type unclear) | - |
| Lock Screen / Live Activity / Dynamic Island | No | Y Live Activity | Y Live Activity | - | - | - | ? | ? | Y Live Activity + Dynamic Island | Y Lock Screen widget | - | - | - |
| Apple Watch app | No | Y | Y | Y (P) | No | No | No | Y | Y | No | Y | No | No |
| Voice / hands-free | No | - | - | Y | Y (P) | - | Partial (external keyboard/device control) | - | - | - | - | - | - |
| Sync (iCloud or account) | No (local only) | Y account (R: often fails) | Y | Y (P) | Y iCloud | ? | P (cloud storage IAP) | Y iCloud | Y | Y iCloud | Y via Ravelry | Y account | Y account |
| Backup / export | No | ? | Y backup + CSV export | P ("Restore Backup" $9.99) | Y (Dropbox, AirDrop) | - | ? | - | - | Y iCloud backup | ? | - | - |
| Gauge / yardage / shaping calculators | Inside library patterns only | Y (inc/dec, size converter, swatch library) | Y (units, yarn sub) | - | Y (inc/dec evenly, sleeve taper, blanket) | Y (inc/dec, yarn calc, ruler) | - | - | Partial (yarn usage, P) | ? | Y (pooling) | - | - |
| Yarn stash | Y (weight, skeins, yardage, fiber, dye lot) | Y | Y | R (unreliable) | No | Y (premium after 2025, R) | Y (basic) | No | Y (10 free) | Y | Y | No | No |
| Yarn lookup (barcode or Ravelry DB) | No | Y barcode (R) | Y barcode + DB (R: broken) | Ravelry | No | - | ? | No | ? | Y Ravelry DB | Y Ravelry | No | No |
| Needle / hook inventory | Y (US + metric) | Y | Y | ? | No | Y | ? | No | Y | Y | Y | No | No |
| Video / technique help | No | - | No | Partial (YouTube import) | Y video links (P) | Y | No | Y crochet videos | No | No | No | Y | Y (500+) |
| Abbreviations / glossary | Per-pattern abbreviation list in library patterns | Was in Smart Pattern (removed) | - | - | Y Quick Key | - | - | Y lookup | - | - | ? | - | - |
| Social / sharing | No | Y community | No | No | No (Ravelry group) | Y | No | No | Y follow, likes | Share cards | Y Ravelry feed | Y | ? |
| Crochet | Counter and hooks only; patterns knit-only | Y | Y | Y | Y | Y | Pocket Crochet sibling | Y | Y | Y | Y | Y | Y (crochet-led) |
| Generated or size-specific patterns | **Y: 45 designs computed from measurements + gauge** | Stripe generator; Smart Pattern (AI parser) removed 2026 | No | No | No | Fixed patterns | No | No | AI parser shows "only the instructions for your size" | No | No | "view sizes just for you" | AI-made pattern library |
| iPad | Y | Y | Y (+ Mac) | Y | Y (+ Mac) | Y | Y | Y | Y | Y | Y (+ Apple TV) | Y | Y |
| Android | No | No (waitlist) | No | Y | Y | Y | Y | No | Y | No | Y | Y | Y |

Sources for specific cells not on the App Store page: Loopsy Android waitlist and counter quote, [loopsy.com](https://loopsy.com); knitCompanion counters, calculators, timer, Android/Mac and annual $30 plan, [knitcompanion.com](https://www.knitcompanion.com); Loopsy Watch, Live Activity and widgets, its Version History ("Apple Watch app... Live Activity row counter... Quick row counter widgets") on [id6745416564](https://apps.apple.com/us/app/id6745416564); YarnBuddy widgets, Live Activities, backup export and CSV export, its Version History on [id1267678125](https://apps.apple.com/us/app/id1267678125); StitchTally widgets, iCloud and Watch, Version History on [id6738016114](https://apps.apple.com/us/app/id6738016114); CozyKnit Lock Screen widgets, iCloud backup and Ravelry import, Version History on [id6755319044](https://apps.apple.com/us/app/id6755319044); LooseLoop Watch, Live Activity, chart row view and "AI Pattern Parser (BETA)", Version History on [id6756404492](https://apps.apple.com/us/app/id6756404492); Stash2Go widget and Watch counters, Version History on [id1463278276](https://apps.apple.com/us/app/id1463278276); Ribblr widgets, Version History on [id1529605339](https://apps.apple.com/us/app/id1529605339).

### 2c. Other apps worth knowing (one line each)

- **Ravit, kntd:discover, Stash2Go II, Unraveled, Stashora**: Ravelry clients. Unraveled (released 2026-06-16) has widgets and a $7.99 one-time unlock and says "NO SUBSCRIPTION. NO ADS. NO TRACKING." ([listing](https://apps.apple.com/us/app/id6761283301)); Stashora (2026-06-25) adds Siri and a Live Activity row counter ([listing](https://apps.apple.com/us/app/id6782335296)).
- **Knitting Genius** ([id1318598164](https://apps.apple.com/us/app/id1318598164)): "Personalize the design and size of your project. The pattern will adapt!" with 40+ patterns; IAP shows per-pattern $2.99 and "All patterns" $4.99 while the description says all patterns are free (conflict, unverified which applies). 52 ratings since 2017.
- **KnitsThatFit Sweaters** ([id1182812124](https://apps.apple.com/us/app/id1182812124)): custom pullovers and cardigans from gauge and measurements, $14.99 one-time; no update since 2025-03-31.
- **Tin Can Knits** ([id6444720146](https://apps.apple.com/us/app/id6444720146)): single patterns $6 to $9 in-app, size view, step tracking.
- **Knitrino** ([id1495475758](https://apps.apple.com/us/app/id1495475758)): kits with in-app patterns: "see only the size you're making", charts in your yarn colors, left-handed stitch videos; no PDF import by design.
- **Cast Along** ([id6760704901](https://apps.apple.com/us/app/id6760704901)): free calculators (yarn sub, yarn calculator with stash check, size finder, swatch check, increase/decrease spacing, bust darts) plus counters, timers and row reminders; 4.96 on 56.
- **KnitHub** ([id6769869291](https://apps.apple.com/us/app/id6769869291)): toolkit with AR gauge measuring, shaping calculator, abbreviations, iCloud, no account.
- **Nysta** ([id6780839360](https://apps.apple.com/us/app/id6780839360)): finds patterns for yarn you own and checks "enough yarn for your size"; $4.99/mo or $34.99/yr.
- **Yarn Hoarder** ([id6748589361](https://apps.apple.com/us/app/id6748589361)): barcode stash with a community yarn database; Premium $7.99.

---

## 3. Review mining: the top 6

The six with the most US ratings among apps knitters use for tracking or patterns: YarnPal, Loopsy, knitCompanion, My Row Counter, YarnBuddy, Knit&Note (Knit&Note is small but is the knit-first pattern-library subscription closest to Ravel). LooseLoop is added as the fastest-growing 2026 entrant. Review feed URLs are listed in Method.

### 3a. Share of 1 to 2 star reviews that are about money (price, paywall, trial, charges, refunds)

| App | Reviews read | 1 to 2 star | Of those, about money |
|---|---|---|---|
| Loopsy | 399 | 187 | 140 (75%) |
| YarnPal | 679 | 346 | 179 (52%) |
| Knit&Note | 57 | 31 | 19 (61%) |
| knitCompanion | 342 | 71 | 27 (38%) |
| My Row Counter | 726 | 35 | 11 (31%) |
| YarnBuddy | 248 | 38 | 9 (24%) |
| LooseLoop | 65 | 15 | 8 (53%) |

### 3b. Per app: praise, pay triggers, cancel and 1-star triggers

**Loopsy (4.75, 17,196)**
- Praise: "I love the row counter widget on my phone lock screen" (5*, 2026-10-09). "store all of my patterns and stash right here together" (5*, 2026-10-07). "I love that it has a timer" (5*, 2026-08-25).
- Paid because: Smart Pattern: "The pattern conversion to steps... makes it worth it alone." (5*, 2025-09-18). Cross-device: "use the app on both my iPad and my phone" (5*, 2025-10-28).
- Cancelled / 1-star: forced trial, "They force you to do the two week free trial" (1*, 2026-11-10); "charged the $43 and then refused to refund" (1*, 2026-11-09); removed paid feature, "the smart patterns I already had disappeared. Mid project." (1*, 2026-10-09); "getting a new phone and losing all of my inventory" (1*, 2026-10-09); "Wish I'd realized it wouldn't sync before I paid for pro" (1*, 2026-02-15).

**YarnPal (4.71, 35,478)**
- Praise: tutorials for beginners, "I love the tutorials & explanations" (5*, 2026-10-30).
- Paid because: "paying the $40 yearly subscription... it's a total game changer!" (5*, 2026-10-07).
- 1-star: AI content, "AI generated incomplete or wrong instructions" (1*, 2026-11-15); price, "who is gonna pay 40 DOLLARS just to access some tutorials!" (2*, 2026-11-16); "I cancelled the subscription... my $44 was still taken" (1*, 2026-11-12). Knitters feel shut out: "all I could find was a bunch of crochet pattern" (2*, 2026-01-17). AI-related words appear in 124 of its 346 low reviews.

**knitCompanion (4.83, 6,929)**
- Praise: keeps your place on hard charts; "I just love how this program grows along with me." (5*, 2026-03-26).
- Paid because: tracking tools; "I happily pay the annual subscription for access to all the bells and whistles" (5*, 2026-08-26); "worth every penny" (5*, 2025-09-07).
- 1-star: lifetime buyers forced onto a subscription, "my 'lifetime' purchase was not as advertised" (1*, 2026-11-13); "Bait and switch" (1*, 2026-07-23); migration to the new app lost patterns, "I cannot get my patterns moved from the older app" (1*, 2026-07-01). Wishes: "I wish I could mark a project 'complete'" (5*, 2025-12-18), a project timer (5*, 2025-09-16), "ability to print from KC or export pdf" (5*, 2024-10-19). No update since 2025-12-15.

**My Row Counter (4.84, 4,005; 4.87 on 15,928 on Play)**
- Praise: "The row highlighting feature that links to your counter is my favorite." (5*, 2026-11-09); "holds your place across devices" (5*, 2026-11-09); "I love the highlight features and the timers." (5*, 2026-10-28); Watch counting (earlier report, 2026-10-21).
- Paid because: sync and support, "I upgraded to premium to sync across my devices" (5*, 2026-10-24); "the $10/year for premium is so well worth it!" (5*, 2026-10-19). 31 "worth it" sentences in its sample, the most of any app.
- 1-star: features moved behind the paywall, "Make all features free again!" (1*, 2026-09-06); "Opens to white screen" after reinstall (1*, 2026-07-03); "no one time purchase" (1*, 2026-01-17).
- Wishes: "auto creation of secondary counters based on pattern" (5*, 2026-10-28); "a repeat counter for those pattern where you repeat rows 1-8" (5*, 2026-05-27); "a one time purchase option similar to YarnBuddy, Knitflow, Ravit" (4*, 2025-11-11).

**YarnBuddy (4.46, 807)**
- Praise: "I love the highlight line when you open a pattern" (5*, 2026-01-10); "a versatile tracker... not a front end for a specific pattern source" (5*, 2026-10-26); stash appears in 65 of its 180 high reviews.
- Paid because: lifetime option, "It's fantastic to have an option to do a one time purchase" (5*, 2026-11-11); "Just switched to lifetime subscription because I can't live without it." (5*, 2026-10-04).
- 1-star / 2-star: broken yarn database and barcode scan, "The yarn database remains useless" (2*, 2026-11-07); designer-scraping accusation (1*, 2026-09-27); Watch sync (3*, 2026-06-02).
- Wishes: "Would love a screen widget that lets me count rows without unlocking." (4*, 2024-06-24, since shipped); "stop the timer from my lock screen" (4*, 2026-02-23); last-row alert on a counter (5*, 2026-01-23).

**Knit&Note (3.93, 194)**
- Praise (inside low reviews): "the most aesthetically pleasing knitting companion I've seen" (2*, 2026-01-26).
- 1-star: subscription for a basic tracker, "$100 annually in this economic climate for a basic app" (2*, 2026-01-26); stash paywalled after cataloguing, review titled "Greedy" (1*, 2026-07-19); update cut off charts and lost highlights (1*, 2026-07-08); "I would've responded more to a freemium model" (1*, 2026-08-20).

**LooseLoop (4.58, 309, released 2025-12-29)**
- Praise: AI step-by-step guides from your PDF, "My favorite feature is the Pattern Guide." (5*, 2026-09-20); "made following more complicated patterns so much easier" (5*, 2026-11-14); "I love that they have a lifetime purchase option" (5*, 2026-11-13).
- 1-star: the AI parser erred, "Got my charts completely wrong" after 5 hours of socks (1*, 2026-10-18); onboarding loops; "Influencers are given free credits" (2*, 2026-09-11). Wishes: markup on the PDF (2*, 2026-09-11), Live Activity (5*, 2026-01-29, since shipped).

### 3c. What makes knitters pay, and what makes them leave (across all seven)

Pay triggers, in order of how often reviewers name them: (1) sync across iPhone and iPad and not losing data (My Row Counter, Loopsy); (2) guided step-by-step from a pattern (Loopsy Smart Pattern, LooseLoop guides); (3) PDF/chart markup and highlight linked to the counter (knitCompanion, My Row Counter); (4) a one-time or lifetime option for people who refuse subscriptions (YarnBuddy, LooseLoop); (5) Watch and lock-screen counting (My Row Counter, Loopsy, YarnBuddy).

Leave / 1-star triggers: (1) a trial forced before any free use, or a charge after cancelling (Loopsy, YarnPal); (2) features taken away or moved behind a paywall after people relied on them, including lifetime purchases not honored (Loopsy, knitCompanion, My Row Counter, Knit&Note); (3) lost data on a new phone or broken sync (Loopsy, knitCompanion); (4) AI-made or wrong instructions (YarnPal, LooseLoop); (5) broken yarn databases and barcode scans (YarnBuddy).

---

## 4. Table stakes vs differentiators

### 4a. How often each missing feature comes up

Counted across the 2,108 reviews dated 2024-01-01 or later, all 11 apps (praise, complaints and requests together; regex hits).

| Feature Ravel lacks or has partially | Reviews mentioning | Apps where it comes up | Ravel today |
|---|---|---|---|
| Sync / backup / lost data | 74 | 10 of 11 | None (local SwiftData only, no export) |
| PDF highlight / annotate / markup | 66 | 9 | One row band, no markup |
| Ravelry | 66 | 8 | None |
| Charts (reading with a ruler) | 41 | 5 | Band only, no column marker |
| Project timer | 38 | 6 | None |
| Apple Watch | 36 | 6 | None |
| Multiple / linked counters | 32 | 4 | Two counters, repeat position only |
| Export / print | 21 | 7 | None |
| Stitch counter | 20 | 6 | None outside library steps |
| Project photos | 18 | 5 | None |
| Barcode / label scan | 18 | 5 | None |
| Widget / Lock Screen / Live Activity | 17 | 5 | None |
| Row reminders / alerts | 17 | 5 | None |
| Voice / hands-free | 16 | 3 | None |
| Video / tutorials | 189 (mostly YarnPal beginners) | 8 | None (abbreviation list only) |
| Android | 5 | 5 | None |

### 4b. Ranked gaps a real knitter will notice in week one and hold against Ravel

Ranked by mention frequency, adjusted for how quickly a new user hits the gap and whether competitors' free tiers already cover it.

1. **No backup, sync or export.** 74 mentions in 10 of 11 apps; the top 1-star reason after money. An iPad owner notices on day one ("holds your place across devices" is a top My Row Counter praise). Free iCloud sync is already standard in StitchTally, CozyKnit, KnitHub and YarnBuddy. Ravel's own rule says a row count must never be lost, and today a lost phone loses every count.
2. **PDF reader is a single band.** 66 mentions in 9 apps for highlight/annotate, plus 41 for charts. PDF knitters (the core paying tracker segment) expect a movable highlighter linked to the counter, a vertical column marker for charts, and the ability to write on the page. YarnBuddy gives the bars free.
3. **No counting without opening the app: widget, Lock Screen / Live Activity, Watch.** 53 mentions in 6 apps, and every serious 2025 to 2026 entrant shipped them (Loopsy, YarnBuddy, StitchTally, LooseLoop, CozyKnit, Stashora). Requested even in praise reviews. Watch reliability is a 1-star risk when it drops taps (YarnBuddy).
4. **Counters too simple: only two, no linked or auto-resetting counter, no reminders at a row.** 32 counter mentions plus 17 reminder mentions; sock, sleeve and lace knitters run 3 to 7 counters ("7 for my typical barefoot socks", Loopsy). "Remind me at row N" covers the buttonhole and "at the same time" problem knitCompanion sells.
5. **No Ravelry import.** 66 mentions in 8 apps. Ravelry still has no official app and five clients are active; a knitter's library and stash live there. A store name one syllable from "Ravelry" invites the question "does it connect to Ravelry?".
6. **No project timer.** 38 mentions in 6 apps; cheap to build; knitCompanion users ask for it, YarnBuddy and Loopsy users name it as a favorite.
7. **No project photos (progress and finished object).** 18 mentions; every tracker in the matrix except knitCompanion has them; Ravel uses photos only as pattern pages.
8. **No PDF "Open in Ravel" / share-sheet import** (Ravel's `Info.plist` declares no document types). From the earlier report (knitCompanion "open with" complaints); a first-week friction for anyone downloading a Ravelry PDF in Safari.
9. **No standalone calculators** (gauge, yarn needed, increase evenly). Low mention count (8), but whole new apps exist for it (Cast Along 4.96, KnitHub), and Ravel already owns the math in its engines.
10. **No yarn lookup** (barcode or Ravelry database). 18 mentions, but reviewers also say the databases that exist are broken (YarnBuddy). Lower priority.
11. **No voice counting.** 16 mentions in 3 apps; a loyal minority (My Row Counter, knitCompanion).
12. **No technique help beyond abbreviations.** Huge for beginner crocheters (YarnPal), smaller for knitters. Ravel's per-pattern abbreviation list is a start.
13. **Android.** 5 mentions; Loopsy has a waitlist. Not a launch gap for an iOS-first app.

### 4c. What Ravel has that nobody else has

1. **Patterns computed from the knitter's measurements and gauge, across 45 designs including sweaters to 5X and a kids' raglan 2T to 12.** The only live comparables are KnitsThatFit (sweaters only, 127 ratings, last update 2025-03-31, [listing](https://apps.apple.com/us/app/id1182812124)) and Knitting Genius (40+ patterns, 52 ratings, [listing](https://apps.apple.com/us/app/id1318598164)). Bellish, the venture-backed version of this idea, is gone (see 2a). LooseLoop, Loopsy, Ribblr, Knitrino and Tin Can show "only your size" from a fixed pattern; none recompute stitch counts for a new body or gauge.
2. **Deterministic math, not AI, with a test suite at every size and yarn weight.** The fastest-growing rivals now run AI parsers (LooseLoop "AI Pattern Parser", YarnPal, the Gemini/OpenAI "Stitch Fiddle Row Tracker"), and their 1-stars are AI errors ("Got my charts completely wrong", LooseLoop, 2026-10-18). Only Ribblr publicly takes the same "no AI" side ([Ribblr, 2026-05-06](https://meet.ribblr.com/t/a-message-from-me-about-ai-patterns/724441)).
3. **A cast-on pattern is frozen and cannot change or vanish.** Directly answers the most damaging 2026 review pattern: Loopsy removed Smart Pattern mid-project, knitCompanion's legacy lifetime buyers lost access, Tin Can wiped progress (earlier report). No competitor promises this.
4. **Pattern problem reports that flow back as a correction offered at the row you are on.** No competitor has this.
5. **The whole tracker free, with no account, no ads, no network and no project cap.** Not unique alone (Cast Along is free for now, Unraveled is one-time), but no app that also sells a pattern library keeps its tracker free: Loopsy caps imports, YarnBuddy caps 10 projects, LooseLoop caps stash at 10 yarns and one active project, Knit&Note paywalls stash.
6. **The row counter drawn as growing fabric in the project's yarn color.** Unique, though no reviewer asks for it (earlier report).
7. **Inches/yards or cm/m chosen by region inside the pattern text.** Others offer converters, not localized pattern output.

---

## 5. Pricing read

| Group | Monthly | Yearly | Lifetime / one-time | What the money buys |
|---|---|---|---|---|
| **Ravel** | $6.99 | $39.99 | $79.99 | Pattern library only; tracker free |
| Library-plus-AI apps: YarnPal, Loopsy, Woolsy, LoopCraft | $3.99/wk to $8.99/mo | $39.99 (all four list it) | Loopsy $99.99 (a reviewer calls it "$100 for a one time fee", 2025-08-28) | Hundreds to 1,000+ patterns, videos, sync, stash, counters |
| Knit-first library: Knit&Note | ~$9.99 (per reviews; no monthly IAP listed now) | $107.99 | none | 1,200+ patterns, tracker, stash |
| Trackers with sync: My Row Counter, YarnBuddy, StitchTally, CozyKnit, KnitHub, Knitflow | $1.99 to $4.99 | $9.99 to $24.99 | $24.99 to $79.99 (Knitflow $79.99, YarnBuddy $44.99, CozyKnit $44.99) | Sync, Watch, markup, unlimited projects |
| Newer premium trackers: Stashora, Yarnzy, LooseLoop | $4.99 to $14.99 | $29.99 to $49.99 | Yarnzy $79.99 / $99.99; LooseLoop $99.99 (period not stated) | Ravelry sync, AI parsing, Live Activity |
| Per-pattern / custom-fit | n/a | n/a | Knitting Genius $2.99 per pattern, $4.99 all; Tin Can $6 to $9 per pattern, $36 unlimited projects; KnitsThatFit $14.99 | Single patterns |
| Ravelry clients | $2.29 (ads off) | $6.49 to $9.99 (ads off) | Ravit $4.99, Unraveled $7.99, Stash2Go $29.99 | Ravelry on mobile |

Read:
- **$39.99 yearly is the category's standard top price**, and every app charging it bundles a large library plus tracker conveniences. Ravel charges the same for 45 designs while its tracker lacks the conveniences rivals bundle. Knitters will compare on catalogue size first ("If there was video for each pattern and more patterns it would be worth the 39", YarnPal 1*, 2026-02-14).
- **$79.99 lifetime is no longer an outlier.** The earlier report said the highest lifetime seen was $44.99; that is out of date: Knitflow and Yarnzy list $79.99, Loopsy and LooseLoop list $99.99 tiers (period not stated, so lifetime is unverified for those two). Lifetime buyers are vocal fans (YarnBuddy, LooseLoop), but knitCompanion shows the cost of ever reneging on one.
- **$6.99 monthly is high for the category** (trackers $1.99 to $4.99; only Woolsy $8.99, Knit&Note ~$9.99 and Yarnzy $14.99 are higher), and close to the price of one indie pattern ($6 to $9 at Tin Can Knits).
- **Per-pattern buying is cheap where it exists**: Knitting Genius sells an adapting pullover for $2.99 and the whole set for $4.99 (IAP list; conflicts with its "all free" description). A knitter who finds that will see Ravel's subscription as steep.

What knitters say about subscriptions in this category:
- Subscription fatigue is explicit: "I refuse to add another subscription to my monthly bills" (Loopsy 1*, 2025-09-04); "If it were a one time fee I could consider it" (Loopsy 1*, 2025-12-26); "I am subscription weary" (LooseLoop 5*, 2026-11-13).
- Small yearly fees for a tool used daily are accepted: "$10/year for premium is so well worth it!" (My Row Counter 5*, 2026-10-19).
- Paying for basics that used to be free is punished hardest: "Make all features free again!" (My Row Counter 1*, 2026-09-06); "$100 annually... for a basic app" (Knit&Note 2*, 2026-01-26).
- Trials that bill before people understand them drive the worst reviews (Loopsy 75% of low reviews are money).

---

## 6. What changed in 2026

- **Flood of new entrants, almost none with traction.** Of 118 craft apps returned for "knitting", "row counter", "knitting row counter", "knit counter", "crochet counter", "knitting patterns" and "yarn stash", 61 were first released in 2026 and 53 of those have fewer than 10 ratings ([iTunes Search](https://itunes.apple.com/search?term=knitting%20row%20counter&country=us&entity=software)). The 2026 ones with any traction: Woolsy (231, AI-style library clone of YarnPal by seller "Easy Carb"), Cast Along (56, calculators), Stashora (20) and Unraveled (32) as new Ravelry clients, Yarnzy (18), KnitHub (6).
- **Late-2025 entrants grew fast on AI guides and Live Activity**: LooseLoop (released 2025-12-29, 309 iOS ratings, 443 on Play) leads with an AI pattern parser and lock-screen counting; CozyKnit (2025-11-18) with iCloud, Lock Screen widgets and Ravelry import.
- **Loopsy's 2026 arc**: added Apple Watch, Live Activity and widgets, a Queue with Ravelry import, Discover with "Loopsy Verified Designers", and a "10 fresh imports every week" free tier; removed the paid Smart Pattern parser mid-project and drew a run of 1-stars ([Version History](https://apps.apple.com/us/app/id6745416564)). Android still a waitlist ([loopsy.com](https://loopsy.com)).
- **knitCompanion moved legacy lifetime users to a $30/yr subscription** via a new app ("knitcompanion-ng" in its store link per [knitcompanion.com](https://www.knitcompanion.com)) and has not shipped an iOS update since 2025-12-15; 1-stars on 2026-07-23 and 2026-11-13 cite lost lifetime access.
- **AI pattern apps proliferated but did not catch on**: Yarnbie (149 ratings), Yarn AI (82), Patternize (1), Yarno (3), InterTwined (5), LoopKnit AI and the Gemini/OpenAI "Stitch Fiddle Row Tracker" (7) ([lookup](https://itunes.apple.com/lookup?id=6758268844,6743322760,6749139586,6757073515,6762224069,6815132635&country=us)).
- **Platforms turned against AI patterns**: Etsy banned AI-generated "functional instructions" including knitting and crochet patterns on 2026-10-22, with proactive enforcement planned for early 2027 ([Value Added Resource](https://www.valueaddedresource.net/etsy-bans-ai-patterns/)). Ribblr's co-founder wrote "Ribblr says NO to AI patterns" on 2026-05-06 and reports removing over 100 in 2026 ([Ribblr forum](https://meet.ribblr.com/t/a-message-from-me-about-ai-patterns/724441)). A LoveCrafts designer-handbook page requiring AI disclosure was reported by search as dated February 2026, but the page now returns 404 (unverified).
- **Ravelry**: no 2026 platform announcement found. Its blog's 2026 posts are pattern features only (2026-02-19, 2026-03-06, 2026-07-18; [blog.ravelry.com](https://blog.ravelry.com/)). Its apps directory still says "There is no official Ravelry app" and now lists 2026 newcomers Stashora, Unraveled, InterTwined and Loopsy ([ravelry.com/about/apps](https://www.ravelry.com/about/apps)). No published Ravelry AI policy was found (unverified; the earlier report's Plagiarism Today source says it removes obvious AI patterns). No Ravelry API change found (unverified).
- **Bellish appears to have shut down** (domain redirects elsewhere; not in US App Store), see 2a.

---

## 7. Checks on the earlier report (2026-11-13)

- Rating counts confirmed and slightly up: YarnPal 35,226 to 35,478; Loopsy 17,142 to 17,196; Knit&Note 190 to 194 (3.91 to 3.93); My Row Counter 3,971 to 4,005.
- Knit&Note's "$9.99/mo" is no longer in the App Store IAP list (now $107.99, $14.99, $11.90); a 2026-08-20 review still cites "$9/month". Treat the monthly price as unverified.
- "Highest lifetime seen is $44.99" (R-10) is wrong: Loopsy's $99.99 tier was already in the earlier table, and Knitflow and Yarnzy list $79.99. Ravel's $79.99 lifetime sits mid-pack.
- "My Row Counter: Watch, widget" holds for Watch (App Store lists Apple Watch); no widget statement was found in its listing or notes (unverified).
- "Pocket Knitting sync is paid" confirmed (Cloud storage IAP $1.99 / $19.99).
- "Custom-fit apps have almost no App Store traction" strengthened: Bellish disappeared; KnitsThatFit has not updated since 2025-03-31.
- Ravel's library is now 45 designs (store description), not 20, so the earlier R-02 and R-07 concerns about catalogue size are partly addressed; catalogue size is still small next to every $39.99 competitor.

---

## Sources

App Store pages (US): https://apps.apple.com/us/app/id + 6738537088, 6745416564, 1058142783, 1234214894, 6752294439, 1572271760, 1342608792, 1251317736, 1545599414, 1267678125, 1529605339, 6738016114, 6756404492, 6759599166, 1634163608, 6444720146, 1182812124, 1553071325, 1495475758, 6755319044, 6760704901, 1318598164, 1463278276, 6761283301, 6782335296, 6809693241, 6740465748, 6815132635, 6769869291, 6780839360, 6748589361.

iTunes APIs: https://itunes.apple.com/lookup?id=<ids>&country=us ; https://itunes.apple.com/search?term=<term>&country=us&entity=software ; review feeds https://itunes.apple.com/us/rss/customerreviews/page=<1-10>/id=<id>/sortby=<mostRecent|mostHelpful>/json for 6745416564, 6738537088, 1058142783, 1342608792, 1267678125, 1634163608, 6756404492, 1529605339, 6755319044, 1553071325, 6738016114.

Google Play: https://play.google.com/store/apps/details?id= + com.row_counter, com.create2thrive.knitcompanion, com.knitandnote.android, com.ribblr.app, com.yarnpal.ai, com.looseloop.app, com.samaitch.kntd, com.com.knitrino, app.tincan, com.luxx.Stash2GoII, com.rfsp.pocketknitting, com.enhancient.android.ravit, com.tricoton, androiddeveloperjoe.knittingbuddy, com.jamilxt.stitchtally, com.knirirr.beecount (404).

Other:
- Loopsy site: https://loopsy.com
- knitCompanion site: https://www.knitcompanion.com
- Ravelry apps directory: https://www.ravelry.com/about/apps
- Ravelry blog: https://blog.ravelry.com/
- BeeCount on F-Droid: https://f-droid.org/en/packages/com.knirirr.beecount/
- Bellish (2020 figures): https://www.blackbird.vc/portfolio/bellish ; https://www.purewow.com/home/bellish-knitting-app ; bellish.co redirect observed 2026-11-20
- Stitch Fiddle: https://www.stitchfiddle.com/en
- LoveCrafts about: https://www.lovecrafts.com/en-us/pages/about-lovecrafts ; AI handbook (404 on 2026-11-20): https://www.lovecrafts.com/en-us/c/article/designer-handbook-ai
- Etsy AI pattern ban: https://www.valueaddedresource.net/etsy-bans-ai-patterns/ ; https://alternativeto.net/news/2026/10/etsy-cracks-down-on-ai-slop-bans-ai-generated-patterns-and-recipes-and-tightens-photo-rules/
- Ribblr on AI patterns: https://meet.ribblr.com/t/a-message-from-me-about-ai-patterns/724441
- Plagiarism Today on Ravelry and AI: https://www.plagiarismtoday.com/2025/11/24/the-ai-invasion-of-knitting-and-crochet/
