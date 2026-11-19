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
