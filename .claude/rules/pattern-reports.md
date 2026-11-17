---
paths:
  - "Shared/Patterns/**"
  - "Shared/Services/PatternReport.swift"
  - "RavelTests/ReportedPatternsTests.swift"
  - "RavelTests/PatternReportTests.swift"
  - "scripts/pattern-report.py"
---

# Pattern reports (2026-11-16)

A knitter who says a pattern does not work is believed until the rebuilt plan proves otherwise. Every
library project keeps a `PlanSource` (design, measurements, gauge, revision) in its frozen plan, so the
exact pattern can be rebuilt.

## How a report arrives

Guided project, menu, "Report a Problem": an email to the support address with the knitter's words, the
step and row as written, and one `ravel-report <base64>` line.

## Triage

1. `scripts/pattern-report.py "<email text>"` prints the code and the line that rebuilds the plan.
2. Rebuild it in `ReportedPatternsTests`, read the reported step and the steps around it, and knit-check
   the math by hand (stitch counts, decreases per round, row parity, measurements at the stated gauge).
3. Confirmed: add a test in `ReportedPatternsTests` that fails on the report, then fix the engine.
4. Fix the class, not the case: add the check to `PlanCheck` so every design at every size and yarn
   weight is held to it (`PatternTests` runs them all). Topical designs pass through `PlanCheck` too.
5. Raise the design's entry in `Design.revisions`; for a seasonal design whose record was wrong (not its
   base engine), raise the record's `"revision"` in `docs/designs.json` instead (publishing needs Jack's yes).
   A seasonal project's revision is its base engine's plus its record's, so either fix reaches it.
   A record past its `ends` date leaves the shelf but still offers its fix, as long as it stays in the list:
   never delete a record that projects were cast on from. Older revisions of a record are in the git history
   of `docs/designs.json`, for rebuilding a report filed against one. Projects cast on at a lower revision
   show "This pattern was corrected", the changed section names and an Update button; `Project.adopt` keeps
   the knitter on the same step and row. Nothing changes without their tap.
6. Reply to the knitter, and ship the build.

Not confirmed (a misread instruction, a gauge that did not match the swatch): reply with the fix, and if the
instruction was easy to misread, reword it. Rewording alone does not raise the revision.
