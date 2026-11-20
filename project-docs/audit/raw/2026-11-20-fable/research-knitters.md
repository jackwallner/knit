# Ravel launch research: what knitters say, 2026-11-20

Point of view: the knitters this app is for. Builds on `project-docs/audit/raw/research-competitors.md` (competitor table, pricing, review mining by money, first AI section) and does not repeat it.

## Method and limits (read first)

- **Reddit could not be read.** reddit.com returns 403 to scripts, the web search tool refuses the domain, Claude in Chrome blocks it as a restricted site, and the working mirrors sit behind a bot-check page, which I did not try to get around. Every Reddit point below comes from a search-engine summary and is marked **unverified**. r/knitting, r/craftsnark and r/AdvancedKnitting threads were not read first hand.
- **Ravelry forums need a sign-in**, which I did not do. Public Ravelry pattern pages were read directly; project counts below come from those pages, read 2026-11-20.
- **App Store reviews**: the newest 2,629 unique US reviews across 12 knitting apps (YarnPal, Loopsy, knitCompanion, My Row Counter, YarnBuddy, Knit&Note, Tin Can Knits, Pocket Knitting, LoopCraft, Ribblr, Knitrino, KnitsThatFit), from the iTunes RSS feed, up to 10 pages each, mined with keyword regexes for first-run, hands-busy, AI, photo and fit themes. Counts are indicative, not statistics. Sample: https://itunes.apple.com/us/rss/customerreviews/page=1/id=6738537088/sortby=mostrecent/json (same pattern for each app id).
- I also read Ravel's own repo to check claims against what ships (sample photos, design page contents, store copy).
- Quotes are under 15 words.

---

## 0. Finding from the repo that changes the launch: the "knitted sample" photos are AI-generated

Every library design page shows a photo the code calls "A knitted sample" (`Ravel/Views/LibraryView.swift` line 299; `Shared/Patterns/Design.swift` line 141). `project-docs/README.md` says these were made with an image generator, "made to pass for real finished-object phone posts". `project-docs/sample-photos/style.txt` asks for an image "indistinguishable from a real, unedited photo". 45 designs ship with one (`Ravel/Assets.xcassets/Samples`). The store description says the math is "not AI".

What knitters and platforms say about exactly this:
- Etsy (2026-10-22) bans AI-generated patterns and from 2026-11-07 requires pattern sellers to show at least one real, unedited photo of a finished result made from the pattern. https://www.valueaddedresource.net/etsy-bans-ai-patterns/
- Ribblr's guidelines ban AI images "showing products not actually made" from a real pattern. https://ribblr.com/contentpolicy and https://ribblr.com/learn/how-to-know-if-a-crochet-pattern-is-ai
- TKGA (2026-08-10) lists "Rendered-looking images, with no real samples" as an AI tell, and says Ravelry has a "strict NO AI policy" (TKGA's claim; Plagiarism Today found no written Ravelry policy, only removals). https://tkga.org/recognizing-ai-in-knitting/ and https://www.plagiarismtoday.com/2025/11/24/the-ai-invasion-of-knitting-and-crochet/
- A designer's blog says Ravelry is "removing designer accounts who use AI generated photos" (secondhand, unverified). https://www.donnaestin.com/post/the-quest-for-authentic-photos-in-knitting-patterns
- Knitters already use reverse image search, C2PA and SynthID checks, and fiber-halo and texture tells. https://yarn-enchantment.com/2026/07/21/how-to-spot-ai-generated-crochet-knitting-in-2026-3991/
- YarnPal shows what happens when an app says "not AI" while its images are generated: in its newest 500 US reviews, 113 mention AI or slop (103 of those at 1 or 2 stars), at a steady 15 to 30 percent of reviews every month of 2026. Reviewers stop believing the denial: "I don't care how much they say it's not ai" (2026-06-25); "developers respond... created by humans, but they absolutely are not" (2026-11-15). Six reviews say finished items looked "nothing like the picture". https://apps.apple.com/us/app/id6738537088

Read: an AI photo presented as a real knit sample, next to a "not AI" claim, is the single most damaging thing a knitting app can ship in late 2026. This also sits close to App Review 2.3 (accurate metadata) if those images reach screenshots or previews (the current `docs/` screenshots use the drawn garment, not the photos). Decided 2026-11-20: Jack keeps the photos. Options considered are in section 3.

---

## 1. Who the buyer is

### Population signals
- 2024 yarn consumer survey (7,000+ respondents, presented by Berroco's GM, so skewed to yarn-brand followers): 84 percent knit, 73 percent crochet, 58 percent do both; 69 percent of knitters also crochet; 53 percent of knitters knit every day; average age 58, 98 percent women, 48 percent retired; 70.4 percent get inspiration mainly from Ravelry. https://craftindustryalliance.org/the-size-of-the-yarn-market-yarn-consumer-survey-results-2024/
- Craft Yarn Council tracking (2014, n=3,178): 51 percent enjoy making things for others; 90 percent use the internet to find patterns; Ravelry used by 71 percent. https://craftyarncouncil.com/node/6
- Younger knitters are real and arrive through video: #knittok over a billion views (https://www.bigissue.com/life/tiktok-knitting-crochet-gen-z-fashion); a Mintel figure cited by SBS says 86 percent of Gen Z did a craft project last year (https://www.sbs.com.au/news/article/why-young-people-are-picking-up-knitting/odykneez0).

### Segments

| Segment | What they want from a phone app | Evidence | Will they pay for sized patterns? |
|---|---|---|---|
| Beginner (often teen or young adult, often crochet first) | Video for a stitch they do not know, stitch count after each row, no paywall on basics | 138 of 2,629 reviews mention being a beginner; YarnPal beginner: "who is gonna pay 40 DOLLARS" (2026-11-16); "written without a stitch count after each round... TERRIBLE" (YarnPal, 2026-01-30) | Rarely. They download and rate; they churn at a paywall. Ravel's free tracker plus free designs is right for them |
| Returning knitter | Pick up exactly where they left off, months later | knitCompanion: "Put down a project for months... knew right where to start" (2019-06-30); Knit&Note: "after having a baby" (2025-10-24) | Sometimes, if the app is stable. Hurt most by updates that move or wipe things |
| Gift and seasonal knitter | Quick hat, mittens or blanket by recipient size, a deadline, yardage | Gift timing advice runs July to December, with "panic" knitting in December: https://www.interweave.com/article/knitting/panic-last-minute-knitting/ and https://blog.lionbrand.com/?p=15921 | Yes, short-term: a month of access for kids' sizes before December is the natural sale. Expect churn in January |
| Garment knitter (sweaters, cardigans) | Fit: ease guidance, schematic, a size that matches their body, not a label | Ravelry project notes on CustomFit (below); first-sweater fit failures come from ease and gauge: https://elizabethsmithknits.com/2025/08/22/lessons-learned-from-my-first-sweater/ | **Most likely to pay**, especially knitters whose bodies sit outside standard grading (larger bust, long torso, tall, plus size). This is the segment CustomFit served for a decade |
| Sock knitter | Foot circumference and length, heel and toe choice, any gauge | Rachel Leggett's free Sock Pattern Generator: 455 Ravelry projects, 4.8 from 65 votes (https://www.ravelry.com/patterns/library/sock-pattern-generator) | Some, but free generators already exist |

Which segment pays: garment knitters who have been burned by standard sizing, plus gift knitters for children's sizes in Nov to Dec. Accessories (scarf, cowl, dishcloth) are not a pay trigger; they are free everywhere (prior research).

---

## 2. How knitters choose and trust a pattern

What knitters check before casting on, and whether Ravel's library (no designer names, generated or drawn samples) reads as a red flag on that point.

| Signal | What knitters do | Source | Ravel today | Red flag? |
|---|---|---|---|---|
| Real photo of the finished piece, ideally on a body | "good photos of the finished piece before I buy"; want "detailed views from all angles" | https://www.crazypatterns.net/en/forum/topic/166877/what-do-you-expect-from-a-paid-pattern | AI-generated "sample" photos on every design | **Yes, the worst one** (section 0). No photo is better than a fake one |
| Photos on several body sizes | Larger knitters say samples are almost never shown on their bodies | https://sewing.craftgossip.com/the-sewing-community-has-a-fatphobia-problem-and-its-time-we-fix-it/ ; a designer showing herself at different sizes: https://ravelry.com/patterns/library/agnes-sweater-mama | None | Yes for garments up to 5X |
| Ravelry project pages from other knitters | "my favorite way to vet a pattern" is Ravelry Projects; look for errors others found | https://www.hookedbykati.com/?p=29 ; find "someone who has finished a sweater" like yours: https://threadpanda.substack.com/p/how-to-knit-yourself-a-sweater-part | None; library patterns are not on Ravelry | Yes. A pattern with zero makes reads as untested |
| Designer reputation and traceable maker | "If I cannot trace where an image originated, that is my first red flag"; new shop under a year: "vet more rigorously" | https://yarn-enchantment.com/2026/07/21/how-to-spot-ai-generated-crochet-knitting-in-2026-3991/ ; https://knithacker.com/2026/04/trusting-your-spidey-sense-how-i-spot-fake-ai-generated-patterns-shops/ | No designer name (by rule), new developer, new app | Yes, on its own. Not fatal if the maker of the app is visible and the method is shown |
| Test knitting | TKGA lists test-knit info as a trust sign; "an AI pattern has never been knitted, let alone tested" | https://tkga.org/recognizing-ai-in-knitting/ ; https://theknittingtimes.com/2026/02/02/how-ai-is-damaging-the-knitting-community/ | Software checks every size; nothing hand-knitted is claimed. The site says "Every design is tested at every size" (`docs/index.html` line 723) | Yes, and the word "tested" will be read as test-knitted. Say "checked by software at every size" until real test knits exist |
| Errata | Knitters expect corrections and trust designers who reply | https://www.knitpicks.com/help/35 ; designer "immediately rewrote the pattern" (crazypatterns thread above) | Report a Problem plus fix offered to cast-on projects | No. A strength; make it visible (a public change log) |
| Schematic with finished measurements | Look for "schematics, or at least very clear measurements" | https://knotions.com/how-to-identify-a-pattern-thats-good-for-you/ | Finished size text on the design page; no drawn schematic | Mild for accessories, real for sweaters |
| Gauge | Want both stockinette and in-pattern gauge before buying (r/AdvancedKnitting, unverified search summary) | https://reddit.birdcat.cafe/r/AdvancedKnitting/comments/zzszgv/what_do_you_look_out_for_in_a_pattern | Gauge is an input; pattern adapts to it | No. This is Ravel's clearest advantage |
| Yardage | Standard part of a complete pattern | https://www.garnstudio.com/pattern.php?cid=18&id=7928 | Shown, recalculated per size | No |
| Difficulty and techniques list | Check "the specific techniques required" rather than a level label | https://knotions.com/how-to-identify-a-pattern-thats-good-for-you/ | Level shown; no techniques list found in the design page | Mild |
| Size inclusivity | Sizing backlash is recurrent (PetiteKnit size range on TikTok, 2025) | https://www.aol.com/scandal-rocked-internet-knitting-community-051715305.html ; https://karie-westermann.squarespace.com/blog/some-thoughts-on-size-inclusivity-in-knitting | Baby to 5X, any measurement | No. A selling point if proven with real makes |
| Ease guidance | "Will the recommended ease work for you?"; first sweaters fail on ease | https://craftdoodling.substack.com/p/before-you-cast-on ; https://elizabethsmithknits.com/2025/08/22/lessons-learned-from-my-first-sweater/ | Ease is added in code (`Design.sweaterEase`); not explained to the knitter as far as I found | Yes for sweaters: knitters will ask "body or finished chest?" |
| Free preview of the pattern text | Read a free sample "to judge the writing style before buying" | https://www.hookedbykati.com/?p=29 | Opening rows shown free at the knitter's size | No. Strong, keep it |

Summary: Ravel already has the hard-to-copy proof (gauge-driven math, stitch counts on every step, yardage, free opening rows, errata flow). It lacks the human proof knitters rely on (real makes, real photos, a traceable maker). The generated photos turn that gap into an active red flag.

---

## 3. The AI question

### Community temperature, 2025 to 2026
- Hostile and organized. Etsy ban (2026-10-22) with a real-photo rule; Ribblr bans and removes AI patterns; LoveCrafts requires AI disclosure as the first sentence of the listing (https://www.lovecrafts.com/pages/designer-handbook-ai); TKGA pledges no AI (2026-08-10).
- Designers: Louise Tilbrook says AI sock patterns are "regurgitated" from scraped free patterns; a reader will "continue to avoid anything AI" (https://everydayknitter.substack.com/p/ai-cant-help-you-knit). Kate Davies and Jagged Lines covered in prior research.
- Satire as protest: a free "AIlephant" pattern mocking AI patterns (https://knitting.craftgossip.com/knit-back-at-ai-patterns-with-the-ailephant/2026/09/04/).
- Drama travels fast: weekly scandals spread on TikTok and Instagram, including a 2025 accusation of using AI to copy a goose pattern (https://www.aol.com/scandal-rocked-internet-knitting-community-051715305.html). Outsiders seen as extracting from the craft get swarmed (Knitting.com buyers, 2022: https://www.thedailybeast.com/tech-bros-dave-bryant-and-mike-jackness-bought-knittingcom-it-didnt-go-well).
- r/knitting "Anybody else sick of seeing AI generated knitting" (2024, title only, unverified) and r/crochet bans on AI content (search summary, unverified): see prior research.

### What knitters accept
- Calculators, spreadsheets and pattern generators built on knitting math are long accepted. Pamela Costello's free Incredible Custom Fit Raglan worksheet has 2,423 Ravelry projects and 4.4 stars (https://www.ravelry.com/patterns/library/incredible-custom-fit-raglan); Knitting Fool's Top Down Raglan Generator has 738 projects (https://www.ravelry.com/patterns/library/top-down-raglan-sweater-generator); CustomFit had 3,854 (below). None of them drew AI complaints in what I found. An AI-skeptical Substack recommends rule-based tools over AI for custom fit (https://aiknitting.substack.com/p/ask-claude).
- So the line knitters draw: arithmetic from a known method is fine; text or images from a model are not. Ravel's engines are on the right side; its photos are on the wrong side.

### Is "patterns that write themselves" risky?
Yes. It describes what an LLM does. It no longer appears in public copy (only in code comments), which is right. "Written to your size" and "every stitch count is rewritten to fit" (store description) are close to the line; "calculated" or "worked out from your gauge" is safer. Avoid "AI", "smart", "magic", "generate", "instantly".

### What wins trust versus "AI slop"
1. **Remove the generated photos before launch, or replace them with real ones.** Options, in order of trust: real hand-knitted samples photographed plainly (even a few, starting with the sweater, a hat and mittens); the drawn garment the app already has (honest, clearly an illustration); a generated image labeled as an illustration (still risky under Etsy-style norms and in knitter eyes). Do not keep images styled to pass as real.
2. **Name the method, not a designer.** "Each design is a set of knitting rules, the same arithmetic as a percentage-system sweater, worked out from your gauge" with the method credited (Elizabeth Zimmermann's percentage system is the reference knitters know; Kniterator cites it: https://api.ravelry.com/patterns/library/kniterator-custom-fit-patterns). Keep "no designer names" (no invented people), but show who made the app.
3. **Show the math.** Stitch count after every step is already there. A schematic with finished measurements and the ease added ("finished chest = your chest + 4 in") would answer the garment knitter's first question.
4. **Earn real makes.** A small test-knit round (Yarnpond or Ravelry test groups: https://yarnpond.com ; how calls work: https://payhip.com/PatternDesignCircle/blog/pattern-design-circle-blog/a-knitting-pattern-designer-s-guide-to-test-knitting-what-why-and-how-pattern-testing-works) at several sizes, with permission to show their photos and a "knitted by testers" line. Testers usually want a free pattern and enough time.
5. **Use precise words.** "Checked at every size by software" until something is hand-knitted; "test knitted" only for what was.
6. **Keep the free opening rows and the errata flow visible.** They are the proof a scam shop cannot fake.

---

## 4. Precedents for sized and custom-fit pattern products

| Product | What it was | Outcome | What knitters said | Lesson for Ravel |
|---|---|---|---|---|
| CustomFit (Amy Herzog, later with Meg Anderson Kilfoil) | Web tool: your measurements plus swatch give a sweater pattern; per-pattern about $9.99 to $12.50 or a subscription | 3,854 Ravelry projects, 4.6 stars. Announced closure Jan 2021, sold to "a fellow knitter" Feb 2021, then shut down 2024-06-15; customfit.com is now a parked domain | Fit stories mixed: bottom fit, upper torso and armhole did not (https://www.ravelry.com/projects/AtomicAthena/customfit); expect "a few tries" (https://www.ravelry.com/projects/knitternaut/customfit); blogger: both sweaters "fit exactly as I want them to", but switched from subscription to buying one at a time because swatching for a subscription was a struggle (https://quiteayarnblog.com/2020/03/07/customfit-experience/) | Real demand, small and loyal, among garment knitters; tied to a named human expert. Subscription friction is real for slow sweater knitters. Shutdown notice (https://www.customfitknits.com/) gives no reason; Ravel's frozen per-project plan answers the "what happens to my patterns" fear |
| KnitsThatFit Sweaters / Premium | iOS custom sweater generator, $14.99 premium | 126 and 84 US ratings since 2015/16 | Loved by machine knitters and long-time users; killed by bugs and math: "401 yards of yarn for a men's sweater" (2024-11-09); counter came back with the "WRONG COUNT" (2026-08-31); "would fit Barbie" (2022-08-06) | One visible math or counter error defines a sizing app |
| Bellish | Free iOS generator for jumpers and cardigans (Australia, 2020), claimed 250,000 user designs | Pattern discontinued on Ravelry; bellish.co now redirects to an unrelated site | Launch press only (https://www.frankie.com.au/article/this-app-generates-custom-knitting-patterns-in-a-jiffy-551381) | Free generator plus press did not become a business |
| Knitrino | Curated kits and patterns, row-by-row with tap-a-stitch videos, pay per pattern | 111 US ratings, 4.37, since 2020 | Fans adore it: "work on just one row at a time" (2024-04-04); founders named and present at Zoom knit nights | Row-at-a-time guided knitting is loved; trust comes from named people and real designers |
| Tin Can Knits app | Publisher's own patterns in-app, one size shown | 138 US ratings, 4.08 | "without having to circle all the numbers for my size" was the hope; then app numbers differed from the PDF (2023-06-25); a later update wiped progress (prior research); all patterns in app Jan 2026, size switching added (https://blog.tincanknits.com/2025/10/02/whats-next-for-the-tin-can-knits-app/) | Size-only view is the hook; mismatched numbers and lost progress are the killers; knitters change size mid-project |
| Sweater Wizard (Carole Wulster) | Desktop software for custom sweater schematics and text | Discontinued | Learning curve; reviewer had to redo a top (https://agatheringofwool.blogspot.com/2005/09/sweater-wizard-review-revised.html) | Setup friction loses casual knitters |
| Knitting Fool, Incredible Custom Fit Raglan, Rachel Leggett generators | Free web calculators and worksheets | 738, 2,423 and 455 Ravelry projects | Long-lived, well rated | Free competition for the core math; Ravel must win on guidance, proof and the tracker |
| Stitch Maps (JC Briar) | Grid-free charts, subscription for row highlighting | Niche, still online (https://stitch-maps.com) | "made the chart look like the knitting" (https://knitting.craftgossip.com/checking-out-stitch-maps/2013/06/26) | Specialist tools survive on a small paying core |
| Ysolda Teague's size chart | Free, detailed body-measurement chart used by many designers | Widely cited (https://knitty.com/sizing.html) | Seen as filling gaps in standard sizing | Citing an open, known size chart for Ravel's standard sizes would add credibility (unverified which chart Ravel's engines use) |

Scale check: one popular human-designed sweater, Tin Can Knits' Flax, has 33,772 Ravelry projects (https://www.ravelry.com/patterns/library/flax). Every custom-fit tool above sits one or two orders of magnitude below that.

---

## 5. First five minutes, and while knitting

### Delete moments (review mining, 2,629 reviews)
- **Forced setup before use**: 47 reviews about sign-up or login, 30 of them at 1 or 2 stars. Loopsy: "incredibly long list of questions you HAVE to answer" (2026-02-28).
- **Paywall or trial pushed at launch, "free" that is not**: 11 explicit, nearly all 1 or 2 stars. Loopsy: "immediately pushed into a free trial. That's not free forever" (2026-06-05).
- **Ads, and ads that promised "free"**: 110 mentions, 62 at 1 or 2 stars.
- **Lost work after an update**: 39 mentions, 22 at 1 or 2 stars. Loopsy "Wiped everything!" (2026-04-27).
- **AI content** (YarnPal): section 0.
- **Accessibility**: a blind crocheter could not finish setup with VoiceOver (YarnPal, 2026-05-29).
Ravel already avoids the first four by design. The rating ask after a finished project or a 20-row visit is well placed.

### While knitting (hands busy, yarn in the way)
- **Count without picking up or unlocking the phone** is the most requested hands-busy feature: "count rows without unlocking" (YarnBuddy, 2024-06-24); "stitch counter widget... Lock Screen" (Knit&Note, 2023-12-31); Apple Watch counting is a main reason people pay for My Row Counter and YarnBuddy, and its sync bugs are a main 1-star cause ("without needing my phone in the room", 2025-03-16). Lock-screen and Dynamic Island counting is now standard in newer apps (Strikk, Alicia's Row Counter listings: https://apps.apple.com/us/app/id1560737474).
- **Voice counting** is loved where it exists: "don't have to stop crocheting to turn a counter" (My Row Counter, 2024-02-05); knitCompanion users note TV noise can trigger it (2019-01-21).
- **Screen sleep**: reviewers ask for keep-awake (https://apps.apple.com/us/app/id310821956) and praise it where present (https://apps.apple.com/us/app/iknitting/id838879886). Ravel keeps the screen awake inside a project (`ProjectView.swift` line 126). Good.
- **Big tap targets and undo**: accidental-tap complaints are rare (16 mentions, 4 low), which suggests tap-anywhere plus undo works.
- **Picking up months later**: knitters value landing on the exact row (knitCompanion, Knitrino reviews above).
- **Changing size mid-project** happens (Tin Can Knits blog above).
Gap for Ravel: no Lock Screen, widget, Live Activity, Watch or voice counting.

---

## 6. Does crochet matter?

- Most knitters also crochet: 58 percent do both; 69 percent of knitters crochet (2024 survey above). Older CYC data had 63 to 66 percent doing both (2009 to 2011).
- The biggest apps in the category are crochet-led (YarnPal, Loopsy) and their reviews are mostly crochet.
- But "no crochet" is a rare complaint against knit-first apps: 7 of 2,629 reviews. The sharper complaint is being misled: Knit&Note ads mentioned crochet but "There's not anything for crochet" (2023-05-23). An advanced knitter left Ribblr over "questionable crochet amigurumi" (2025-01-29).
- Read: keep the counter and stash crochet-friendly (Ravel does, and says the library is knitting only, which is the honest framing). Do not advertise crochet patterns. Crochet sized patterns are a later expansion, not a launch need. A KnitsThatFit reviewer asked for a crochet version of custom sizing (2021-05-13), a hint of demand.

---

## 7. Launch and growth: the first thousand real users

### Channels
- **Reddit (r/knitting, r/knittinghelp, r/AdvancedKnitting)**: rules not readable here (unverified). Typical big hobby subs ban or restrict self-promotion; general guidance is disclose you built it and keep promotion to about 10 percent of activity (https://reachfront.ai/guides/reddit-marketing-for-apps). r/craftsnark (about 14,000 members in 2022 per press coverage) is where a misstep gets dissected, not where to launch. Expect to post only if the rules allow it, as the maker, asking for feedback, with no AI imagery anywhere.
- **Ravelry**: 70 percent of surveyed knitters draw inspiration there. Ravelry lists third-party apps that use its API (Loopsy, YarnBuddy, knitCompanion, Pocket Knitting and about 35 more) with active-user counts (https://www.ravelry.com/about/apps). A Ravelry connection (import projects, stash or pattern PDFs) would earn a listing there. Ravelry runs its own small-advertiser ad system for fiber businesses, historically pay-per-click, impression or flat rate (2012 description: https://blog.ravelry.com/how-does-ravelry-make-money/; current rates unverified). LYS logo and text ads were listed at $10 and $5 a month (search summary, unverified).
- **Indie Design Gift-A-Long**: a six-week Ravelry holiday event for indie designers, 2025 sale ran Nov 20 to 26 and the event to Dec 31 (https://api.ravelry.com/bundles/gift-a-long-2025-194). 2026 dates not confirmed (unverified). It is designer-based, so Ravel cannot join as a library without designers.
- **KALs and gift timing**: Christmas KALs run Nov to Dec (https://www.ravelry.com/patterns/library/christmas-joy-mkal). Gift-knitting advice tells knitters to start in summer and panic in December, so a late-November launch catches only quick gifts (hats, mittens, baby items). A Ravel "December gift KAL" for a hat or mittens at the recipient's size is a natural hook.
- **Knit-tok and Instagram**: views are large and trends spread fast (Sunday Express via search: #Knitting views up 176 percent 2023 to 2025, unverified). The content that works is real hands and real yarn. Any generated image will be called out.
- **Knitting podcasts and YouTube**: run on yarn-company sponsor slots and Patreon (https://podcasts.apple.com/us/podcast/down-cellar-studio-podcast/id509929387 ; https://podcasts.apple.com/us/podcast/verypink-knits/id1130124620). A sponsor slot costs money (needs Jack's yes); a free-code review by a podcaster does not.
- **Test knitters**: the cheapest credible channel. Testers post Ravelry project pages and photos, which is exactly the proof Ravel lacks (Yarnpond calls often require a Ravelry project page).
- **Local yarn shops**: no documented app and LYS partnership found; shops do run their own apps and loyalty (https://apps.apple.com/us/app/arkansasyarnco/id1514688506). A free counter to recommend at the register is plausible but unproven (unverified).

### What the store page needs to convert this audience
1. Real proof in the first screenshots: the free counter and fabric (function first), then a real hand-knitted item made from a Ravel pattern if one exists. No generated imagery.
2. "Free, no account, works offline" stated plainly (already done), and the price before the trial (already done).
3. One honest line on method: calculated from your gauge with knitting arithmetic, checked by software at every size, no AI text or images. That line only holds once the photos are fixed.
4. Consistency: the description says 45 designs and the Garter Scarf and Dishcloth are free; the promo text says "A raccoon hat, two more patterns" are free; the site schema and review notes say 32 designs. Pick one set of facts.
5. A visible maker: who built it and how to reach them. Knitters forgive a solo developer who answers; they punish a faceless one.

---

## Sources (beyond those inline)

- App Store review feeds: iTunes RSS for ids 6738537088, 6745416564, 1058142783, 1342608792, 1267678125, 1634163608, 6444720146, 1553071325, 6752294439, 1529605339, 1495475758, 1182812124 (US, sortby=mostrecent).
- Ravelry pattern pages read 2026-11-20: https://www.ravelry.com/patterns/library/customfit , https://www.ravelry.com/patterns/library/incredible-custom-fit-raglan , https://www.ravelry.com/patterns/library/top-down-raglan-sweater-generator , https://www.ravelry.com/patterns/library/hat-pattern-generator , https://www.ravelry.com/patterns/library/sock-pattern-generator , https://www.ravelry.com/patterns/library/flax
- CustomFit history: https://quiteayarnblog.com/2021/02/21/random-knitting-world-news/ , https://www.customfitknits.com/
- Knitrino listing: https://apps.apple.com/us/app/knitrino-curated-kits/id1495475758
- KnitsThatFit listing: https://apps.apple.com/us/app/knitsthatfit-sweaters/id1182812124
- Craft Industry Alliance on Etsy AI: https://craftindustryalliance.org/etsys-ai-problem
- Modern Daily Knitting on fake patterns: https://www.moderndailyknitting.com/community/how-to-spot-ai-fake-pattern/
