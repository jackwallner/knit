#!/usr/bin/env python3
"""Validate fastlane/metadata for every App Store locale.

Hard limits fail the run (exit 1). Target ranges only warn.
Stdlib only. Usage: python3 scripts/validate-metadata.py [metadata_dir]
"""

import re
import sys
import unicodedata
from pathlib import Path

LOCALES = (
    "ar-SA bn-BD ca cs da de-DE el en-AU en-CA en-GB en-US es-ES es-MX fi fr-CA fr-FR "
    "gu-IN he hi hr hu id it ja kn-IN ko ml-IN mr-IN ms nl-NL no or-IN pa-IN pl pt-BR "
    "pt-PT ro ru sk sl-SI sv ta-IN te-IN th tr uk ur-PK vi zh-Hans zh-Hant"
).split()

REQUIRED = [
    "name.txt", "subtitle.txt", "keywords.txt", "description.txt",
    "promotional_text.txt", "support_url.txt", "marketing_url.txt", "privacy_url.txt",
]
URL_FILES = {
    "support_url.txt": "https://jackwallner.github.io/knit/support.html",
    "marketing_url.txt": "https://jackwallner.github.io/knit/",
    "privacy_url.txt": "https://jackwallner.github.io/knit/privacy-policy.html",
}
TERMS_URL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
PRIVACY_URL = "https://jackwallner.github.io/knit/privacy-policy.html"

NO_SPACE_SCRIPTS = {"ja", "ko", "zh-Hans", "zh-Hant", "th"}
CJK_PROMO = {"ja", "ko", "zh-Hans", "zh-Hant"}
ENGLISH_LOCALES = {"en-US", "en-GB", "en-AU", "en-CA"}

BLOCKED_KEYWORDS = {
    "ravelry", "knitandnote", "knit&note", "knitsthatfit", "knitcompanion", "yarnpal",
    "loopsy", "loopcraft", "hobbii", "etsy", "pinterest", "youtube", "tiktok",
    "instagram", "apple", "iphone", "ipad", "watch", "ios", "kntd", "tincanknits",
}

# A non-English listing must tell the reader the app is English only.
ENGLISH_WORDS = {
    "ar-SA": ["الإنجليزية", "الانجليزية"], "bn-BD": ["ইংরেজি"], "ca": ["anglès"],
    "cs": ["angličtin"], "da": ["engelsk"], "de-DE": ["englisch"], "el": ["αγγλικ"],
    "es-ES": ["inglés"], "es-MX": ["inglés"], "fi": ["englann"], "fr-CA": ["anglais"],
    "fr-FR": ["anglais"], "gu-IN": ["અંગ્રેજી"], "he": ["אנגלית"],
    "hi": ["अंग्रेज़ी", "अंग्रेजी"], "hr": ["engles"], "hu": ["angol"],
    "id": ["inggris"], "it": ["inglese"], "ja": ["英語"], "kn-IN": ["ಇಂಗ್ಲಿಷ್"],
    "ko": ["영어"], "ml-IN": ["ഇംഗ്ലീഷ"], "mr-IN": ["इंग्रजी"], "ms": ["inggeris"],
    "nl-NL": ["engels"], "no": ["engelsk"], "or-IN": ["ଇଂରାଜୀ"], "pa-IN": ["ਅੰਗਰੇਜ਼ੀ"],
    "pl": ["angielsk"], "pt-BR": ["inglês"], "pt-PT": ["inglês"], "ro": ["engle"],
    "ru": ["английск"], "sk": ["angličtin"], "sl-SI": ["angleščin"], "sv": ["engelska"],
    "ta-IN": ["ஆங்கில"], "te-IN": ["ఇంగ్లీష"], "th": ["ภาษาอังกฤษ"], "tr": ["ingilizce"],
    "uk": ["англійськ"], "ur-PK": ["انگریزی"], "vi": ["tiếng anh"],
    "zh-Hans": ["英文", "英语"], "zh-Hant": ["英文", "英語"],
}

CURRENCY = (
    r"(?:[$€£¥₹₩₺₽₫฿₪₴]|USD|EUR|GBP|JPY|CNY|INR|KRW|TRY|RUB|BRL|MXN|CAD|AUD|CHF|SEK|NOK|DKK|PLN|"
    r"CZK|HUF|RON|THB|IDR|MYR|VND|ILS|SAR|UAH|PKR|BDT|zł|Kč|Ft|lei|Rp|RM|R\$|kr|元|円|원|บาท|руб|грн|"
    r"₨|Rs)"
)
PRICE_AFTER = re.compile(r"\d\s?" + CURRENCY + r"(?![A-Za-zÀ-ž])")
PRICE_BEFORE = re.compile(r"(?<![A-Za-zÀ-ž])" + CURRENCY + r"\s?\d")

SUPERLATIVES = re.compile(
    r"(?<!\w)(?:best|beste|besten|bestes|bester|meilleur\w*|mejor\w*|migliore|migliori|"
    r"najlepsz\w*|лучш\w*|bäst\w*|bedst\w*|parhaa\w*|paras|melhor\w*|en iyi|"
    r"nejlepší|legjobb\w*|cel mai bun\w*|najbolj\w*|najlep\w*|καλύτερ\w*|"
    r"أفضل|הכי טוב|terbaik|tốt nhất|ดีที่สุด|"
    r"#\s?1|no\.\s?1|nr\.\s?1|number one)(?!\w)|最高|最好|最佳|最棒|최고|베스트|最も|一番",
    re.IGNORECASE,
)
NEGATION_HOOK = re.compile(r"\bnot (?:one|just|only|a|an)\b[^.\n]{0,40}\bbut\b|\bnot one\b", re.IGNORECASE)

failures = []
warnings = []


def fail(loc, msg):
    failures.append(f"{loc}: {msg}")


def warn(loc, msg):
    warnings.append(f"{loc}: {msg}")


def read(path):
    return path.read_text(encoding="utf-8")


def fold(text):
    """Casefold and drop combining dots so Turkish dotted capital I matches."""
    return unicodedata.normalize("NFC", text).casefold().replace("\u0307", "")


def body(text):
    """The file content without its single trailing newline."""
    return text[:-1] if text.endswith("\n") else text


def words(text):
    """Lowercase word tokens, splitting on spaces and punctuation."""
    out = []
    for token in re.split(r"[^\w]+|_", text.casefold()):
        if token:
            out.append(token)
    return out


def check_text_hygiene(loc, name, text):
    if "\u2014" in text:
        fail(loc, f"{name} contains an em dash")
    for match in re.finditer("\u2013", text):
        i = match.start()
        before = text[i - 1] if i else ""
        after = text[i + 1] if i + 1 < len(text) else ""
        if not (before.isdigit() and after.isdigit()):
            fail(loc, f"{name} uses an en dash as a dash at index {i}")
    for ch in "―⸺⸻‒":
        if ch in text:
            fail(loc, f"{name} contains dash character U+{ord(ch):04X}")
    if re.search(r"(?<=\S) -- (?=\S)", text):
        fail(loc, f"{name} uses a double hyphen as a dash")
    if PRICE_AFTER.search(text) or PRICE_BEFORE.search(text):
        fail(loc, f"{name} has a digit next to a currency sign or code")
    if SUPERLATIVES.search(text):
        fail(loc, f"{name} has a superlative or rank claim: {SUPERLATIVES.search(text).group(0)!r}")
    if NEGATION_HOOK.search(text):
        fail(loc, f"{name} has a negation hook")
    if any(unicodedata.category(c) == "Cc" and c not in "\n" for c in text):
        fail(loc, f"{name} has control characters")


def check_keywords(loc, lang, kw, name, subtitle):
    # Multi-word phrases ("kaus kaki") are fine; a space beside a comma wastes a character.
    if re.search(r"\s,|,\s|^\s|\s$", kw):
        fail(loc, "keywords have whitespace around a comma")
    tokens = [t for t in kw.split(",")]
    if any(t == "" for t in tokens):
        fail(loc, "keywords have an empty token")
    folded = [t.casefold() for t in tokens]
    for t in {t for t in folded if folded.count(t) > 1}:
        fail(loc, f"duplicate keyword token {t!r}")
    for t in folded:
        if t in BLOCKED_KEYWORDS:
            fail(loc, f"keyword {t!r} is a blocked third-party name")
    in_name = set(words(name)) | set(words(subtitle))
    joined = (name + subtitle).casefold()
    for t in folded:
        if not t:
            continue
        if t in in_name:
            fail(loc, f"keyword {t!r} repeats a word from the name or subtitle")
        elif lang in NO_SPACE_SCRIPTS and len(t) >= 2 and t in joined:
            fail(loc, f"keyword {t!r} sits inside the name or subtitle")
    if "ravel" in folded:
        fail(loc, "keyword 'ravel' repeats the brand")
    if len(kw) > 100:
        fail(loc, f"keywords are {len(kw)} characters (max 100)")
    elif len(kw) < 94:
        warn(loc, f"keywords are {len(kw)} characters (target 94 to 100)")


def check_description(loc, lang, desc):
    if len(desc) > 4000:
        fail(loc, f"description is {len(desc)} characters (max 4000)")
    lines = desc.split("\n")
    sep = r"(?::|：) "
    if not any(re.fullmatch(r"[^:：\n]+" + sep + re.escape(TERMS_URL), l) for l in lines):
        fail(loc, "description lacks a labelled Terms of Use link on its own line")
    if not any(re.fullmatch(r"[^:：\n]+" + sep + re.escape(PRIVACY_URL), l) for l in lines):
        fail(loc, "description lacks a labelled Privacy Policy link on its own line")
    for needle in ("Garter Scarf", "Diagonal Dishcloth"):
        if needle not in desc:
            fail(loc, f"description does not name the free design {needle!r}")
    if not re.search(r"(?<!\d)7(?!\d)", desc) or not re.search(r"(?<!\d)24(?!\d)", desc):
        fail(loc, "subscription paragraph lacks the 7 day trial or the 24 hour cancel window")
    if lang not in ENGLISH_LOCALES:
        words_needed = ENGLISH_WORDS.get(loc)
        if not words_needed:
            fail(loc, "no English-only check configured for this locale")
        elif not any(fold(w) in fold(desc) for w in words_needed):
            fail(loc, "description does not say the app and patterns are English only")
    if not re.search(r"\bcm\b|centim|centím|сантим|санти|\bm\b|厘米|公分|センチ|센티|سم|סמ|सेमी|সেমি|સે\.?મી|ಸೆಂ|സെ|सें|ਸੈਂ|ସେ|சென்|సెం|ซม|เซนติ|cm\.", desc, re.IGNORECASE):
        warn(loc, "description does not obviously mention centimeters and meters")


def validate(root, loc):
    d = root / loc
    if not d.is_dir():
        fail(loc, "locale directory is missing")
        return
    lang = loc
    texts = {}
    for fname in REQUIRED:
        p = d / fname
        if not p.is_file():
            fail(loc, f"{fname} is missing")
            continue
        raw = read(p)
        text = body(raw)
        if text != text.strip():
            fail(loc, f"{fname} has leading or trailing whitespace")
        if not text:
            fail(loc, f"{fname} is empty")
        if fname != "description.txt" and "\n" in text:
            fail(loc, f"{fname} spans more than one line")
        texts[fname] = text
        check_text_hygiene(loc, fname, text)
    if (d / "release_notes.txt").exists() and loc != "en-US":
        fail(loc, "release_notes.txt must not exist outside en-US in the first version")
    for fname, url in URL_FILES.items():
        if fname in texts and texts[fname] != url:
            fail(loc, f"{fname} differs from the en-US URL")
    if len(texts) < len(REQUIRED):
        return
    name, subtitle, kw = texts["name.txt"], texts["subtitle.txt"], texts["keywords.txt"]
    promo, desc = texts["promotional_text.txt"], texts["description.txt"]
    if len(name) > 30:
        fail(loc, f"name is {len(name)} characters (max 30)")
    elif len(name) < 24 and lang not in CJK_PROMO:
        warn(loc, f"name is {len(name)} characters (target 24 to 30)")
    if not name.startswith("Ravel"):
        fail(loc, "name does not start with the brand Ravel")
    if len(subtitle) > 30:
        fail(loc, f"subtitle is {len(subtitle)} characters (max 30)")
    elif len(subtitle) < 24 and lang not in NO_SPACE_SCRIPTS:
        warn(loc, f"subtitle is {len(subtitle)} characters (target 24 to 30)")
    lo, hi = (65, 85) if lang in CJK_PROMO else (130, 170)
    if not lo <= len(promo) <= hi:
        fail(loc, f"promotional text is {len(promo)} characters (need {lo} to {hi})")
    check_keywords(loc, lang, kw, name, subtitle)
    check_description(loc, lang, desc)
    if "\n\n\n" in desc:
        warn(loc, "description has a run of blank lines")


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "fastlane" / "metadata"
    for loc in LOCALES:
        validate(root, loc)
    extra = sorted(p.name for p in root.iterdir() if p.is_dir() and p.name not in LOCALES and p.name != "review_information")
    for name in extra:
        fail(name, "unexpected locale directory")
    for line in warnings:
        print("warn  ", line)
    for line in failures:
        print("FAIL  ", line)
    print(f"{len(LOCALES)} locales checked, {len(failures)} failures, {len(warnings)} warnings")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
