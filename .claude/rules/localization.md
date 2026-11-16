---
paths:
  - "Ravel/Localizable.xcstrings"
  - "scripts/l10n/**"
  - "Shared/Utilities/Loc.swift"
  - "RavelTests/LocalizationTests.swift"
---

# Localization (A-16, 2026-11-16)

The interface is translated into the 46 languages the App Store listing ships (`fastlane/metadata` folder
names; `no` is `nb`, `de-DE` is `de`, `es-ES` is `es`, and so on), plus English spelling for en-AU, en-CA and
en-GB. One catalog: `Ravel/Localizable.xcstrings`. English text is the key.

## Source of truth

The catalog is generated, so a word is fixed in one place and the catalog rebuilt:

- `scripts/l10n/keys.txt`: the English keys, one per line, numbered by line. `|plural` marks a key with plural forms.
- `scripts/l10n/<code>.tsv`: `number<TAB>text`; a plural key is `one=...|few=...|other=...`.
- `es-MX`, `fr-CA`, `pt-PT` hold only what differs from `es`, `fr`, `pt-BR` and inherit the rest.
- `python3 scripts/l10n/build.py` rewrites the catalog and fails on a lost placeholder, a dash, or a missing key.

A key added in code needs a line in `keys.txt`, a line in every `.tsv` (English variants and the regional
files excepted), and a rebuild. Do not edit the catalog by hand.

## What is translated, and what stays English

- Translated: every label, button, menu, alert, sheet, empty state, paywall string, VoiceOver label and
  announcement, design names, shelf titles, difficulty, size and measurement names, section names, the
  abbreviation meanings, yarn weights, needle kinds, yarn colors, Trending tags.
- English on purpose: generated instructions (`Step.texts`), the materials lines, `PatternPlan.finished`, and
  the abbreviation terms themselves (k2tog, ssk). A wrong machine-translated instruction ruins a garment.
- Topical designs and Trending tags published on the site arrive in English; a tag or title that matches a
  catalog key is translated, any other stays as published.
- Letter sizes (XS to 5X), `DK`, `Aran` and the other weights keep their international names in most languages.
- Lengths and yardage come from `Sizing`, which prints cm and m outside the United States. The unit symbol is
  not translated.

## Rules for code

- SwiftUI literals are `LocalizedStringKey` already. A `String` that reaches the UI is built with
  `String(localized:comment:)`. Text that arrives as an English string from an engine or data goes through
  `Loc.text` or `Loc.section`, which look it up in the catalog and return it unchanged if absent.
- `YarnWeight.label`, `Design.name`, `NeedleKind.label` stay English because the engines and saved plans use
  them. The UI reads `title`.
- Never join a translated noun to a verb ("Go to " + unit). Give each sentence its own key: "Go to Row",
  "Go to Round".
- Plural keys carry the number as the only argument, so the catalog's plural variations apply. Sentences with
  two arguments are split instead of mixing a plural with a second placeholder.
- Accessibility identifiers never use translated text (`Offer.slug`).
- `Wrap` places chips from the trailing edge in a right-to-left language.

## Proof

`RavelTests/LocalizationTests` checks that every language ships and keeps its placeholders. Screenshots in
other languages: `gh-sim launch --args '-SeedDemo -AppleLanguages (de) -AppleLocale de_DE'` (also ar, ja, hi),
screens as in `ipad-layout.md`. Indic knitting terms and Hebrew, Arabic and Urdu wording should get a native
read before the languages are promoted in the listing.
