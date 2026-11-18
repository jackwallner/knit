# Walkthrough as a gift knitter, 2026-11-17

One pass through the app as one target user, written down as found. Nothing was changed.

## Who

The seasonal gift knitter from the segment table in [raw/research-competitors.md](raw/research-competitors.md): knows knit, purl and working in the round, has not knit since last winter, wants a hat for a 6 year old, mittens for a niece and a scarf, all before mid December. Found the app by searching "knitting patterns". Will pay for a month if it saves time, will not pay $39.99 to make three small things.

## How it was tested

- Build 23, Debug, iPhone simulator (390 x 844 points), fresh install, US units.
- First launch with sample prices on the paywall (`-MockProducts`). The paid path used the debug unlock (`-Pro`), since a simulator cannot buy.
- Path walked: first launch, Browse Patterns, Ribbed Beanie in Child size, paywall, close, find a free design, cast on the Garter Scarf, count rows, back out, a plain row counter with a second counter, add a yarn to the stash, force quit and relaunch, then the unlocked Ribbed Beanie through Brim, Crown and Mark Finished.
- Not covered: a real purchase, trial or restore; adding a PDF or photos; iPad; VoiceOver and large text; metric units and other languages; the rating ask; a real phone.

## Findings

Ordered by how much each one costs this user. File references are where the behaviour lives.

### Costs a download, a sale or a count

1. **Tapping Cast On a second time makes a second project that looks like a lost count.** Back from a project that was just cast on returns to the design page, inside the Patterns tab, with Cast On still live. She tapped it to get back to her scarf and landed on "Cast on 32 stitches" at row 0. The Projects list then showed two rows named Garter Scarf, one at 5 and one at 0, with nothing to tell them apart. The guard in `castOn()` only blocks a double tap while the project is open (`Ravel/Views/LibraryView.swift:284`). Screenshot: [raw/2026-11-17-gift-knitter/duplicate-projects.jpg](raw/2026-11-17-gift-knitter/duplicate-projects.jpg).

2. **First launch reads as "this app costs $39.99 a year".** Three pages: an animation, a sweater, then the trial. The page follows the fleet onboarding trial contract (`~/ios/onboarding/trial-conversion-thumb-zone.md`): one tap trial in the Continue slot, "Get Started" as the quiet free exit above it, no plan cards. That structure is deliberate and stays. What cost her was the number: the trial is the yearly plan at $39.99, and someone who has not used the app yet reacts to that figure. Mahj, Cribbity and Bridge pitch the monthly trial in onboarding for this reason and keep yearly leading on the paywall. Corrected 2026-11-17: the first version of this finding faulted the quiet exit and the missing plan choice, which are by design.

3. **Page one says "Tap anywhere to count a row" and tapping does nothing.** The fabric knits itself once and stops (`Ravel/Views/OnboardingView.swift:66`). She tapped it twice, then found Continue.

4. **The library cannot be searched or narrowed, and the free designs are hard to find.** 45 designs on five shelves, no search, no filter for free, for who it is for, or for level. Getting past Hats took four full swipes. The two free designs are marked with a grey "Free" in the same small type as "Easy" on every other tile, the first one sits in the second shelf, and it replaces the level, so a free tile does not say how hard it is. After she closed the paywall she was back on the locked beanie with no pointer to anything she could knit for free.

5. **Two projects from the same design look identical everywhere.** The list row is a name and a bare number (`Ravel/Views/ProjectsView.swift:131`): no size, no "of 576", no finished size. Three hats in three sizes would be three rows named Ribbed Beanie. Inside the pattern the size she picked (Child) is not on screen either; it is only in the Materials sheet as "to fit a 20 in head". Renaming in Details works, but nothing suggests it. Screenshot: [raw/2026-11-17-gift-knitter/project-list.jpg](raw/2026-11-17-gift-knitter/project-list.jpg).

6. **The trial is the whole product for this user.** The paywall says "A pattern you cast on is yours to keep", and it is true: a cast on project keeps its own copy of the pattern. Her obvious move is to start the 7 day trial, cast on the three things she needs at the right sizes, and cancel. That is honest and it earns trust, but for a seasonal buyer it means little or no revenue, and there is no single pattern price to catch her. This is a pricing decision, not a defect.

### Friction once she is knitting

7. **Mark Finished shows nothing in a library pattern.** Part way through the crown she chose Mark Finished. The screen did not change: no check mark, no message. Only the Projects list showed it under Finished. The check mark exists for the PDF layout only (`Ravel/Views/ProjectView.swift:458`).

8. **Size and gauge are forgotten each time a design opens.** Every design page starts at its default size and worsted gauge (`Ravel/Views/LibraryView.swift:142`). Someone knitting for the same child three times picks Child and the same yarn weight three times.

9. **Tiles do not show what the piece looks like.** Every tile is the same stocking stitch drawing cut to a shape. Garter, Ribbed and Seed Stitch scarves differ only by colour, and so do the blankets. The knitted sample photos exist but only on the design page. The counter also draws stocking stitch for a garter scarf.

10. **The stash is a list that connects to nothing she needs.** Linking a yarn to a project copies its name into Details. The design page asks for "about 120 yd of worsted" and cannot say whether her stash covers it, and yardage is never shown as skeins. The stash row shows a bare "1" for skeins. The yarn form opens on five text fields (name, brand, colour, fibre, dye lot) before weight and skeins.

11. **Reading her own PDF is hidden.** The plus button asks only for a name. The PDF goes in through the project's menu as "Add Pattern", a word that also names the paid tab. Nothing on the Projects screen hints that her printed pattern can live here for free.

12. **Tapping a word for help counts a row.** The whole screen is the tap target, so tapping "k2tog" to see what it means knits a row. The abbreviations are spelled out, but under the menu, in Materials.

13. **The stitch count under a decrease round is unlabelled.** "*K8, k2tog; repeat from * around" shows "72 stitches" while 80 are on the needles. It is the count after the round, which is right, but it reads as the count now. Single round steps also drop the "1 of 11" position, so in the crown the only sense of how far is left is the small drawing.

14. **The project menu changes length between steps.** "Go to Round" appears only on steps with several rounds, so Mark Finished and Reset Count move up and down. Aiming for Mark Finished, the tester hit Reset Count. Reset asks first, so nothing was lost.

### Small, or needs a check

15. **Garter Scarf yardage looks high.** The free scarf at 7 x 64 in asks for about 570 yd of worsted and reads "Rows 1-576: Knit". A rough estimate from stitch count puts it at 400 to 470 yd, about a skein less. The engines round up on purpose, but this is the pattern a non payer judges the library by, so it deserves a tech edit look.
16. **Blank white screen on a cold first launch**, 6 to 8 seconds before the cream first page. Debug build on a busy simulator; check on a phone.
17. **The last grey line of a pattern preview** ("Crown, Finishing") reads as a stray line, not as the sections that come after unlocking.
18. **A stash yarn deletes on swipe with no question** (`Ravel/Views/StashView.swift:28`). Projects with rows do ask.
19. **The Details sheet** uses the system grey grouped look while every other screen is on paper.

## What worked

- No account, no sign in, no ads, no network prompt. From the end of first launch to a counting row counter is two taps and a name.
- Counts held through a force quit: 3, 5 and 0 came back as left.
- The paywall puts the price first, shows all three plans, rewrites the terms line when the plan changes and closes without a fight.
- The design page before paying: sizes by name from Baby to Large, the finished size, yarn amount, both needles, and the first rows written at her size.
- Following a pattern: section name, one large instruction, the stitch count, "round" instead of "row" where it applies, Go to Section, and an undo that cannot be hit by accident.
- The second counter, the question before a reset, and the question before deleting a project with rows.

## Takeaways

- She arrives for one specific gift, not to browse. Her path is Patterns, a hat, a size, the paywall. That path is the strongest part of the app up to the paywall. It breaks at finding the piece (finding 4) and at what happens after she says no (finding 4).
- She makes several of the same thing in different sizes. The app treats each as an anonymous copy (findings 1, 5 and 8).
- What she will pay for is a week or a month, and the app lets her keep what she cast on. Whether to catch her with a single pattern price is the open pricing question (finding 6).
- The free tracker is what would keep her past December, and nothing after first launch shows her that her own printed pattern can live here (finding 11).
- Nothing she did lost a count. The one moment that felt like a lost count was the duplicate project (finding 1).

If these are fixed, the order that follows from the walk: 1, 2 and 3 together, 4, 5, 7.

## Fixed after the walk (build 24)

- 1: back on a design page with the same size and gauge, the button reads Open Project and opens the project already cast on.
- 2: the onboarding trial sells the monthly plan ($6.99). RevenueCat offering metadata `onboarding_plan` = `yearly` switches it back with no build.
- 3: a tap anywhere on the first page knits a row.
- 4: the library has search (names, shelves, levels and size names: "baby hat", "kids mittens") and a Free shelf under Trending; free tiles also show their level.
- 5: a project cast on from the library is named with its size ("Ribbed Beanie, Child").
- 7: Mark Finished shows the check mark in a library pattern.
- 8: a design page opens at the size and gauge last cast on from it.
- 11: the Projects plus button offers Row Counter, My Own Pattern and From the Library.
