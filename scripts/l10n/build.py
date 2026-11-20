#!/usr/bin/env python3
"""Builds Ravel/Localizable.xcstrings from scripts/l10n/keys.txt and the per-language files.

keys.txt: one English key per line, in the order the language files number them from 1.
A key ending in |plural takes plural forms. <code>.tsv: "<number><TAB><text>", and for a plural key
"<number><TAB>one=...|few=...|other=...". Placeholders (%@, %lld, %1$lld) must match the English key.
Run: python3 scripts/l10n/build.py
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).parent
OUT = HERE.parent.parent / "Ravel" / "Localizable.xcstrings"
CATEGORIES = {"zero", "one", "two", "few", "many", "other"}
PLACEHOLDER = re.compile(r"%(?:\d+\$)?(?:lld|@)")


def load_keys():
    keys = []
    for line in (HERE / "keys.txt").read_text().splitlines():
        text, _, kind = line.partition("|")
        keys.append((text, kind == "plural"))
    return keys


def kinds(text):
    return sorted(re.sub(r"%\d+\$", "%", m.group(0)) for m in PLACEHOLDER.finditer(text))


# A regional file holds only what differs from its parent; the rest is inherited.
PARENT = {"es-MX": "es", "fr-CA": "fr", "pt-PT": "pt-BR"}


def read(lang):
    values = read(PARENT[lang]) if lang in PARENT else {}
    for line in (HERE / f"{lang}.tsv").read_text().splitlines():
        if line.strip() and not line.startswith("#"):
            ident, _, value = line.partition("\t")
            values[int(ident)] = value
    return values


def typography(lang, value):
    """French sets a no-break space before ? ! : ;. Canadian French does so before a colon only."""
    if lang == "fr":
        return re.sub(r" ([?!:;])", "\u00a0\\1", value)
    if lang == "fr-CA":
        return re.sub(r" (:)", "\u00a0\\1", value)
    return value


def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


def main():
    keys = load_keys()
    langs = sorted(p.stem for p in HERE.glob("*.tsv"))
    strings = {text: {"extractionState": "manual", "localizations": {}} for text, _ in keys}
    problems = []
    for lang in langs:
        seen = set()
        for ident, raw in read(lang).items():
            value = typography(lang, raw)
            index = ident - 1
            text, plural = keys[index]
            seen.add(index)
            where = f"{lang}:{ident} {text!r}"
            if "\u2014" in value or "\u2013" in value:
                problems.append(f"{where}: dash")
            if plural:
                forms = {}
                for part in value.split("|"):
                    name, _, form = part.partition("=")
                    if name not in CATEGORIES:
                        problems.append(f"{where}: bad plural category {name!r}")
                    forms[name] = form
                if "other" not in forms:
                    problems.append(f"{where}: no 'other'")
                for form in forms.values():
                    if kinds(form) != kinds(text):
                        problems.append(f"{where}: placeholders {kinds(form)} vs {kinds(text)}")
                entry = {"variations": {"plural": {name: unit(form) for name, form in forms.items()}}}
            else:
                if kinds(value) != kinds(text):
                    problems.append(f"{where}: placeholders {kinds(value)} vs {kinds(text)}")
                entry = unit(value)
            strings[text]["localizations"][lang] = entry if plural else entry
        missing = [keys[i][0] for i in range(len(keys)) if i not in seen]
        if missing and not lang.startswith("en"):
            problems.append(f"{lang}: {len(missing)} keys missing, first: {missing[0]!r}")
    # English plural forms live in the catalog too, so one/other read right.
    for text, plural in keys:
        if plural and "en" not in strings[text]["localizations"]:
            one = text.replace("%lld", "%lld", 1)
            singular = {"%lld skeins": "%lld skein", "%lld stitches": "%lld stitch", "%lld stitches after this row": "%lld stitch after this row", "%lld stitches after this round": "%lld stitch after this round", "Try Free for %lld Days": "Try Free for %lld Day", "%lld days free.": "%lld day free.", "%lld projects added": "%lld project added"}[text]
            strings[text]["localizations"]["en"] = {"variations": {"plural": {"one": unit(singular), "other": unit(text)}}}
    catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
    OUT.write_text(json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
    print(f"{len(keys)} keys, {len(langs)} language files, written {OUT}")
    for problem in problems:
        print("PROBLEM", problem)
    sys.exit(1 if problems else 0)


main()
