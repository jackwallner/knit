# Topical patterns loop: plan

Built on `claude/eager-benz-9a5378` and merged into main; ships in 1.0. Records publish only on Jack's yes.

Success criterion: a JSON record on the site becomes a sized, colorwork pattern in the app with no App Store update, every record is proven at every size and yarn weight by a test and a script that CI runs, and a weekly scout drafts records that wait for Jack.

## 1. Colorwork in the engines

New types in `Shared/Patterns/Colorwork.swift`:

- `Palette`: 2 to 4 colors, each a name and a hex value ("Charcoal", `#3B3B3E`). Color A is the main color.
- `Stripe`: a color and a height in inches (not rows), so stripes keep their proportions at every gauge. Rounded to whole rows, at least 1.
- `Chart`: rows of palette letters, `"AABBAA"`, read bottom to top. Width is the stitch repeat. Two placements:
  - `repeat`: the motif runs all the way around (Fair Isle band). The engine rounds the stitch count to a multiple of lcm(engine multiple, chart width). The validator fails the record if that rounding moves the fit more than 5 percent at any size and gauge, so wide repeats on small hats are caught, not shipped.
  - `motif`: one motif centered on the front (a raccoon face), the rest of the round in the background color. Any stitch count works as long as it is wider than the motif plus 4 stitches.
- `Colorwork`: stripes for the body, an optional chart, and where the chart sits (`brim`, `body`, `top`).

Engine rules:

- Round shapes (hat, slouch, rolled hat, cowl, ear warmer, mitts, balaclava top): the chart band is worked in stockinette. On the rib-only shapes (ear warmer, mitt cuffs) the band becomes stockinette between rib edges, and the width measure must leave room for it. Stripes work on any texture; the first round of a new color is knit, so rib and garter do not show color blips.
- Flat shapes (scarf, blanket): stripes on any texture. Charts only on a stockinette panel inside a garter frame (the bordered blanket's body already is one; a scarf with a chart gets 3 garter edge stitches each side). RS rows read right to left, WS rows left to right, and the band ends with the right side facing.
- A chart that does not fit the rows available (a tall motif on a super bulky baby hat) is a validation failure for that yarn weight, and the record lists the weights it allows. The design page offers only those weights; the custom gauge adjusters clamp to the allowed range.
- Floats: no run of one color longer than 5 stitches in a stranded row (7 at bulky and super bulky). Longer runs fail validation.
- A hat with ears (`crown: "ears"`): an ordinary crown, plus two small rounded ears knit flat, rimmed in garter (in a `rim` color of their own) and sewn on. This is what the raccoon beanie needs. (The first draft joined a flat top with a three-needle bind-off, but its pointed corners read as a cat.)

Instructions: every round or row that changes color says it ("Round 5, with B: knit"). Chart rows are written out in words as well as charted ("*K2 A, k3 B, k1 A; repeat from * around"), so the guided view works for someone who cannot read charts.

Plan format (all new keys read with `decodeIfPresent`, so 1.0 plans keep opening):

- `Step.paint: [String]?`: the colors of each row of the step, cycled like `texts`, as palette letters for one repeat ("A" for a plain row, "AABBAA" for a chart row).
- `PatternPlan.palette: [Shade]?`, `PatternPlan.look: Look?` (silhouette and ears), so a cast-on project draws itself from its own frozen plan and never from the record.

Yardage: counted per color from the written rows (stitches in that color, plus floats for each stranded row), each color at least its worked rows plus 15 percent, the main color carrying the rest of the estimate. Materials read "Color A, charcoal: about 140 yd of worsted weight yarn" per color.

Drawing: `Fabric` takes an optional per-row paint and draws each stitch in its color; `Garment` fills its silhouette with the plan's colorwork (stripes and motif visible on the tile, the design page and the guided view's progress piece). Built-in designs draw exactly as today.

## 2. Designs as data

`docs/designs.json` on the site (published records only):

```json
{
  "designs": [{
    "id": "round-raccoon-beanie",
    "title": "Round Raccoon Beanie",
    "base": "ribbedBeanie",
    "crown": "ears",
    "palette": [{"name": "Gray", "hex": "#8A8A8E"}, {"name": "Black", "hex": "#26262A"}, {"name": "Cream", "hex": "#EDE6D8"}],
    "stripes": [{"color": "A", "inches": 2}, {"color": "C", "inches": 0.5}, {"color": "B", "inches": 1.25}],
    "chart": {"placement": "motif", "at": "body", "rows": ["..."]},
    "weights": ["worsted", "aran", "bulky"],
    "tag": "Viral",
    "starts": "2026-11-20",
    "ends": "2027-01-31",
    "requires": 1
  }]
}
```

- `base` is a built-in `Design`: it supplies the engine, the sizes, the measurements and the texture. The record only adds colorwork, a crown option and a title. The engines stay the only source of stitch math.
- `Topical` (in `Shared/Patterns/Topical.swift`) decodes strictly: an unknown base, crown, placement or color letter, a malformed hex, a title over 28 characters, an em dash, or a `requires` above the feature level this build knows, and that record is skipped. The rest of the file still loads.
- `TopicalStore` fetches once a day like `Trending` (same URL rules, same cache-and-keep-on-failure), hides records outside `starts`/`ends`, and never fetches on seeded or `-UITesting` runs. DEBUG `-TopicalDrafts` loads the drafts bundled from `project-docs/topical/drafts/` for screenshots.
- The library gets a `LibraryItem` (built-in `Design` or `Topical`) that `DesignView`, the tiles and the Trending shelf take. `trending.json` may name a published topical id; 1.0 skips names it does not know, which it already does.
- Cast on stores `designRaw = "topical.<id>"` and the full frozen plan with its palette and look. Removing or changing a record never touches a project.
- Paid like the rest of the library (open question below).

## 3. Validation

- The checks `PatternTests` runs move into `Shared/Patterns/PlanCheck.swift` (`PlanCheck.problems(_ plan:) -> [String]`), so the app tests, the topical tests and the script share one set. `PatternTests` keeps calling them, unchanged in strength.
- Topical checks on top: chart fits the count and rows, repeat rounding within 5 percent, floats, every palette color used, yardage per color, flat bands end right side facing, no em dashes, title and tag lengths, a small denylist (team names, brands, character names) for the scout's drafts.
- `RavelTests/TopicalTests` runs every record in `docs/designs.json` and `project-docs/topical/drafts/` at every named size, both range ends and every allowed weight.
- `scripts/topical-check.sh [file...]`: compiles `Shared/Patterns` with a small macOS command-line tool (`swiftc`, no simulator, a few seconds), prints each failure with the size and weight, and writes `previews/<id>.png` per record: the garment drawn in its colors at the default size, the chart grid with a legend, and the yardage per color. Uses the app's own `Garment` drawing so the preview matches the app.
- `.github/workflows/topical.yml`: on any PR or push touching `docs/designs.json`, `project-docs/topical/`, or `Shared/Patterns/`, runs the script on a GitHub macOS runner (free for a public repo), fails on any bad record, and uploads the previews as a build artifact.

## 4. The loop

Runbook at `.claude/rules/topical-loop.md` (paths: `docs/designs.json`, `project-docs/topical/**`, `Shared/Patterns/Topical.swift`), listed in `AGENTS.md`:

1. Scout weekly (Monday 9 AM, a systemd timer on the iMac running `claude --model sonnet` on a clone): the seasonal calendar (holidays, first frost, Valentine's, spring), viral animals and memes on TikTok and Reddit knitting, cold snaps in big markets, sports seasons as colors only.
2. Pick 1 to 3 with a real knitting angle (a shape and colorwork that reads at hat size).
3. Draft the record in `project-docs/topical/drafts/`, run `topical-check.sh`.
4. Fix until it passes, then open a PR `topical/<date>` with the previews. The scout never edits `docs/`, never merges, never touches main.
5. Jack approves in the PR or here.
6. Publish (only on Jack's yes): move the record into `docs/designs.json`, add it to `trending.json` with its tag, merge. GitHub Pages serves it; phones pick it up within a day.
7. Hand the design to the knit-tiktok session (SendMessage) with the preview PNG, title, tag and the one stitch fact worth a video.

Rules the runbook repeats: no designer names or invented people, no characters, logos, brands or team names (team colors only, named plainly: "Navy and orange"), meme animals named by the animal ("Round Raccoon", never the meme's name), lengths through `Sizing`, no em dashes.

## Samples (drafts, not published)

- `holiday-fir-hat.json`: ribbed beanie, cream ground, a 12-stitch fir tree band repeated around, green and red, tag "Holiday".
- `round-raccoon-beanie.json`: ribbed beanie with the ear crown, gray body, a black mask band between cream stripes with a small motif of two eye patches on the front, tag "Viral".

Both validated, with previews in `project-docs/topical/previews/`.

## Order of work

1. `Colorwork`, `Step.paint`, `PatternPlan.palette`/`look`, per-color yardage, ear crown. `PatternTests` green plus new colorwork tests (chart fits at every size and gauge, carry-through, 1.0 plan still decodes).
2. `PlanCheck` extraction, `Topical` decoding, `TopicalStore`, `LibraryItem`, design page and project drawing in color.
3. Script, previews, CI workflow, the two drafts.
4. Runbook, AGENTS.md index line, iMac timer files (`scripts/topical-scout/`). Installing the timer on the iMac is the last step.
5. Full test run on `gh-sim`, screenshots of a topical design page and the guided view in color.

## Open question for Jack

Topical patterns: all behind the subscription like the library, or may a record carry `free: true` for its first week as a TikTok hook? Recommended: allow it, off by default, so a viral pattern can be the free taste that sells the library.
