---
paths:
  - "docs/designs.json"
  - "project-docs/topical/**"
  - "Shared/Patterns/Topical.swift"
  - "Shared/Patterns/Colorwork.swift"
  - "Shared/Patterns/PlanCheck.swift"
  - "Shared/Services/TopicalStore.swift"
  - "scripts/topical-check.sh"
  - "scripts/topical-check/**"
  - "scripts/topical-scout/**"
---

# Topical designs loop

Seasonal and viral designs reach the library as data, with no App Store update: a record in
`docs/designs.json` on the site names one of the library's shapes and adds stripes, a chart, a crown and a
title. The app's engines still write every stitch. `TopicalStore` fetches the list once a day; live records
lead the Trending shelf with their own tag and close their shape's shelf. A cast-on project keeps its whole
plan (palette and silhouette included), so changing or removing a record never touches it.

## The loop

1. **Scout, weekly.** `ravel-topical-scout.timer` on the iMac, Mondays 9 AM, runs `scripts/topical-scout/scout.sh`
   (Sonnet, read and web only, writes nothing outside `project-docs/topical/drafts/`). Sources: the seasonal
   calendar for the next 2 to 6 weeks (holidays, first frost, Valentine's, spring), animals and memes knitters
   share on TikTok and Reddit, cold snaps in big markets, sports seasons as colors only.
2. **Pick 1 to 3** with a real knitting angle: a shape from `Topical.bases` and colorwork that reads at hat size.
3. **Draft** `project-docs/topical/drafts/<id>.json`, one record per file. The scout opens a draft PR
   `topical/<date>`; by hand, do the same.
4. **Check**: `scripts/topical-check.sh` (macOS, a minute) checks every record at every named size, both ends
   of every measurement and every allowed weight, and writes `project-docs/topical/previews/<id>.png`.
   `--print <id>` prints the pattern. CI (`.github/workflows/topical.yml`) runs the same check on every PR and
   uploads the previews. `TopicalTests` runs it in the test suite too.
5. **Jack approves.** Show him the preview PNG and the printed pattern. Nothing is published without his yes.
6. **Publish** (only after that yes): `scripts/remote.py publish <id> --starts <date> --ends <date> --push`
   checks the draft, moves it into `docs/designs.json` (raising `revision` when an already published pattern
   changed) and pushes. GitHub Pages serves it; phones pick it up within a day. To pull one early,
   `scripts/remote.py pull <id> --push` ends it today and keeps the record for the projects cast on from it.
7. **Hand off** to the knit-tiktok session (SendMessage): title, tag, preview PNG, and the one stitch fact worth
   a video.

## Remote control, no app update

`scripts/remote.py status` shows what is live, scheduled and ended, the Trending list and the drafts.
- Designs: `publish`, `pull` (above). Only colorwork on an existing shape (`Topical.bases`) can ship as data;
  a new shape or engine needs a build.
- Trending shelf: `scripts/remote.py feature <id> "<tag>" [--at N]` and `unfeature <id>`. An id is a built-in
  design's raw value or a colorwork id (collection or published); older builds skip ids they do not know.
- Onboarding trial plan: RevenueCat, offering `default`, metadata `onboarding_plan` = `monthly` (the default)
  or `yearly`. Read on every offerings fetch; the paywall always leads with yearly, as on every fleet app.

## Record format (`requires: 1`)

```json
{ "id": "fir-tree-hat", "title": "Fir Tree Hat", "base": "ribbedBeanie", "requires": 1,
  "palette": [{ "name": "cream", "hex": "#EEE6D6" }, { "name": "green", "hex": "#2F5D46" }],
  "brim": "B", "rim": "A", "stripes": [{ "color": "A", "inches": 2 }], "repeatStripes": false,
  "chart": { "placement": "repeat", "stripe": 0, "rows": ["...BB...", "..BBBB.."] },
  "crown": "ears", "weights": ["dk", "worsted"], "tag": "Holiday",
  "starts": "2026-11-20", "ends": "2027-01-01", "free": false }
```

- `palette`: 2 to 4 yarns, lowercase names of 2 to 12 letters (they appear inside rows: "k3 cream"). A is the
  main color: cast on and every row nothing else covers.
- `brim`: color of the shape's edging (its first stretch of texture: brim, cuff, lower border). Stripes then
  count from above it; without it they count from the cast on.
- `stripes`: heights in inches, so they keep proportion at every gauge. Flat pieces and garter round them to an
  even number of rows, so every color change falls on a right-side or knit round. Unless they repeat, they must
  leave at least 3/4 in of color A at the top at the smallest size, or the check fails.
- `chart`: rows top first as the right side shows them, letters A to D, `.` for the stripe underneath.
  `repeat` runs around (the stitch count rounds to a multiple of its width: keep hats to 8 or 4 wide, or the
  fit check fails); `motif` is one centered on the front. `stripe` centers it on that stripe; without it, on
  the longest stretch of stockinette. Charts go on stockinette only: cowls, ear warmers and mitts get a
  stockinette band for them; flat charts need the bordered blanket. `"stitch": "duplicate"` (motifs only)
  leaves the chart's rows plain and adds finishing steps that sew it on afterward: use it for a small motif
  on a round, where knitting it in would carry a yarn all the way around for a few stitches. The picture
  still shows it. A build that does not know the field knits the chart in.
- `crown: "ears"`: two small rounded ears, knit flat in color A, rimmed in garter and sewn to an ordinary
  crown. Beanies only. `rim` colors the rim (the pale edge that makes a raccoon or bear read at a glance).
- `weights`: only the weights the check passes at. Floats are capped at about 1.25 in and never more than
  5 stitches (4 at bulky). Every run of a color, the ground's included, must be 5 or fewer, so a repeat 8 wide
  cannot have a 1-stitch point or a tier wider than 5: use a 4-wide repeat for small pointed motifs. Every plan
  with chart rows says how to carry and catch the floats.
- `free`: off unless Jack asks. The Round Raccoon Beanie is free as the standing TikTok hook (Jack, 2026-11-15:
  "everything at launch, be smart"). The English promotional texts name it ("A raccoon hat"); edit them
  (no review needed) before it is pulled. Everything else is behind the subscription.
- `requires`: bump `Topical.featureLevel` and the record's `requires` together when a field changes meaning,
  so older apps skip what they cannot draw instead of misreading it.

## The bundled collection

`Ravel/collection.json` holds evergreen colorwork designs (Heart, Cherry, Checkerboard, Diamond and Bear
beanies, a Checkerboard Cowl, Heart Mitts) in the same record format, with no dates. They ship in the app,
sit in their shape's shelf after the newest built-ins, and the ones tagged `New` lead Trending. Each needs
a `sample-<id>` photo and its title in every language (`testTheCollectionLoadsWithPhotosAndNames`).
`topical-check.sh` and `TopicalTests` check the file with the published list. Ids must never meet a site
record's id; projects record them as `topical.<id>` like any topical design.

## Rules

- No designer names, invented people, characters, brands, leagues or team names. Teams are colors, named
  plainly ("navy and orange"). Meme animals are named by the animal ("Round Raccoon"), never the meme's name.
  `TopicalCheck.denied` catches the obvious ones; it is a floor, not the rule.
- No em dashes. Lengths in the app go through `Sizing`.
- A change to `Colorwork.swift`, `Painter` or an engine must keep `TopicalTests` and `PatternTests` green and
  every published record passing `topical-check.sh`, because a published record is re-sized live.
