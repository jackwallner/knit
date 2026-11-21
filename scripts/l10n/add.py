#!/usr/bin/env python3
"""Adds new keys and their translations: python3 scripts/l10n/add.py batch.json

batch.json maps each English key to {language code: text} for every language file except the English
variants and the regional files (which inherit). Keys already in keys.txt are skipped. Rebuild after.
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
SKIP = {"en-AU", "en-CA", "en-GB", "es-MX", "fr-CA", "pt-PT"}

batch = json.loads(Path(sys.argv[1]).read_text())
keys = (HERE / "keys.txt").read_text().splitlines()
known = {line.partition("|")[0] for line in keys}
languages = sorted(p.stem for p in HERE.glob("*.tsv") if p.stem not in SKIP)
missing = [f"{key}: {lang}" for key, texts in batch.items() if key not in known for lang in languages if not texts.get(lang, "").strip()]
if missing:
    sys.exit("missing translations:\n  " + "\n  ".join(missing))
lines = {lang: [] for lang in languages}
for key, texts in batch.items():
    if key in known:
        continue
    keys.append(key)
    for lang in languages:
        lines[lang].append(f"{len(keys)}\t{texts[lang].strip()}")
(HERE / "keys.txt").write_text("\n".join(keys) + "\n")
for lang, new in lines.items():
    path = HERE / f"{lang}.tsv"
    text = path.read_text()
    path.write_text(text + ("" if text.endswith("\n") else "\n") + "\n".join(new) + ("\n" if new else ""))
print(f"added {sum(1 for k in batch if k not in known)} keys to {len(languages)} languages")
