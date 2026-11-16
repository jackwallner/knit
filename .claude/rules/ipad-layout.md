---
paths:
  - "project.yml"
  - "Ravel/Info.plist"
  - "Ravel/Views/Layout.swift"
  - "Ravel/Views/ProjectView.swift"
  - "Ravel/Views/Fabric.swift"
  - "Ravel/Views/LibraryView.swift"
  - "Ravel/Views/PaywallView.swift"
  - "Ravel/Views/ProjectsView.swift"
  - "Ravel/Views/StashView.swift"
  - "RavelUITests/ScreenCaptureUITests.swift"
---

# Ravel: iPad layout (G-15, 2026-11-16)

iPad is in from 1.0, free like the rest of the tracker: `TARGETED_DEVICE_FAMILY "1,2"`,
all four orientations in `UISupportedInterfaceOrientations~ipad`, no
`UIRequiresFullScreen`, so Split View and Stage Manager work.

## iPhone stays portrait

The counter is the whole screen as one tap target, and a phone lies flat on a lap
or a table beside the work, where it flips orientation by accident: a rotation
mid-row moves the target under the finger. Landscape on a phone would also leave
about 330 points of height for the instruction and the work together. Revisit
only with a counter layout made for that height.

## How layouts switch

No iPad-only view tree, and no `userInterfaceIdiom` checks in views. Every
switch reads the space a view has (`Ravel/Views/Layout.swift`), so Split View
halves and Stage Manager windows get the phone layout and a phone never reaches
an iPad one. (The enum is `Widths`: a type named `Layout` hides SwiftUI's `Layout`
protocol, which `Wrap` adopts.)

- `Widths.sideBySide` (900 pt, and wider than tall for a project): a project
  puts its reading side (count, instruction or PDF) on the leading side and the
  work beside it. An iPad in portrait (1032 pt on the 13-inch) keeps the stacked
  phone layout for projects; a design page splits from 900 pt in any shape.
- `Widths.farReading` (600 pt both ways): a propped-up iPad is read from further
  away, so the count is 200 pt (128 on a phone), the garment 200 (120), and the
  instruction 1.4 times the phone size, capped at 640 pt wide.
- `readableWidth()`: lists (Projects, Stash) and the narrow design page keep a
  column (680 and 600 pt) through `contentMargins`, so the background, scroll
  indicator and nav bar keep the full width. Screens with a large title pass
  `leading: true` so their rows start under the title; a centered list under a
  leading title looks misaligned. Other screens center the column.

## Per screen

- Counter: count over the work; sideways, count on the leading half and the work
  on the trailing half. The whole screen still knits one row a tap, undo stays
  bottom leading.
- PDF reader: phone and iPad portrait keep the page over a 112 pt strip.
  Sideways, the page takes the leading side and a counter pane (at most 440 pt)
  stands beside it: count, repeat dots and the work, the whole pane one tap
  target, undo at its bottom leading corner. The PDF itself never counts.
- Guided pattern: piece and instruction over the work; sideways, beside it
  (work 45 percent of the width).
- Second counter bar: capped at 520 pt so plus and minus stay near each other.
- `Fabric` with `stitch: 0` sizes stitches to the width but no larger than 52 pt,
  which every phone stays under; without the cap an iPad drew stitches 150 pt wide.
- Library: grid minimum 190 pt at regular width (4 to 6 columns), two columns at
  the accessibility sizes on an iPad, one on a phone. Trending tiles cap at
  420 pt at the accessibility sizes.
- Design page: from 900 pt the piece (420 pt tall) on the leading side, the
  settings in a 480 pt column with Cast On under it.
- Paywall: content capped at 540 by 900 pt and centered; as a sheet it is an
  iPad form sheet.
- Sheets (details, materials, yarn, needle) are form sheets on an iPad unchanged.
- `StoreUnavailableView` names the device (`UIDevice.current.model`).

## Proof

`RavelUITests/ScreenCaptureUITests` launches every main screen, the paywall
(sheet and full screen) and first run, at the default size and at
Accessibility L, in portrait and (iPad only) landscape, and attaches each frame:

    gh-sim test --device "iPad Pro 13-inch (M5)" --only RavelUITests/ScreenCaptureUITests
    gh-sim test --only RavelUITests/ScreenCaptureUITests   # iPhone, portrait only

XCTest is the only headless way to rotate. Landscape attachments come back turned
90 degrees clockwise; rotate them back before judging the frame.
