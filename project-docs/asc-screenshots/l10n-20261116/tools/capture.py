#!/usr/bin/env python3
"""Capture the seven Ravel flows in each language on a leased simulator (iPhone or iPad).

usage: capture.py <udid> <out-root> <asc-locale>[,...]|all [--flows a,b]
Raw frames land in <out-root>/<asc-locale>/<flow>.png. Flows and launch arguments are the ones in
~/ios/appstore-screenshots/configs/knit.json; -MockProducts is always on (a DEBUG simulator build
otherwise shows an Apple Account sign-in). A screen counts as ready once two screenshots in a row
match, so animations have settled. Run `xcrun simctl status_bar <udid> override ...` first (done here).
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import time
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

BUNDLE = "com.jackwallner.knit"
CONFIG = json.loads((Path.home() / "ios/appstore-screenshots/configs/knit.json").read_text())
FLOWS = {f["id"]: ["-SeedDemo", "-MockProducts", *f["launch_args"]] for f in CONFIG["capture"]["flows"]}
# ASC locale -> (AppleLanguages value, AppleLocale)
LOCALES = {
    "ar-SA": ("ar", "ar_AE"), "bn-BD": ("bn", "bn_BD"), "ca": ("ca", "ca_ES"), "cs": ("cs", "cs_CZ"), "da": ("da", "da_DK"),
    "de-DE": ("de", "de_DE"), "el": ("el", "el_GR"), "es-ES": ("es", "es_ES"), "es-MX": ("es-MX", "es_MX"),
    "fi": ("fi", "fi_FI"), "fr-FR": ("fr", "fr_FR"), "fr-CA": ("fr-CA", "fr_CA"), "gu-IN": ("gu", "gu_IN"),
    "he": ("he", "he_IL"), "hi": ("hi", "hi_IN"), "hr": ("hr", "hr_HR"), "hu": ("hu", "hu_HU"), "id": ("id", "id_ID"),
    "it": ("it", "it_IT"), "ja": ("ja", "ja_JP"), "kn-IN": ("kn", "kn_IN"), "ko": ("ko", "ko_KR"),
    "ml-IN": ("ml", "ml_IN"), "mr-IN": ("mr", "mr_IN"), "ms": ("ms", "ms_MY"), "nl-NL": ("nl", "nl_NL"),
    "no": ("nb", "nb_NO"), "or-IN": ("or", "or_IN"), "pa-IN": ("pa", "pa_IN"), "pl": ("pl", "pl_PL"),
    "pt-BR": ("pt-BR", "pt_BR"), "pt-PT": ("pt-PT", "pt_PT"), "ro": ("ro", "ro_RO"), "ru": ("ru", "ru_RU"),
    "sk": ("sk", "sk_SK"), "sl-SI": ("sl", "sl_SI"), "sv": ("sv", "sv_SE"), "ta-IN": ("ta", "ta_IN"),
    "te-IN": ("te", "te_IN"), "th": ("th", "th_TH"), "tr": ("tr", "tr_TR"), "uk": ("uk", "uk_UA"),
    "ur-PK": ("ur", "ur_PK"), "vi": ("vi", "vi_VN"), "zh-Hans": ("zh-Hans", "zh_CN"), "zh-Hant": ("zh-Hant", "zh_TW"),
}


def sim(*args: str, timeout: int = 180) -> subprocess.CompletedProcess:
    return subprocess.run(["xcrun", "simctl", *args], capture_output=True, text=True, timeout=timeout)


def shot(udid: str, path: Path) -> None:
    for attempt in range(4):  # under load simctl can stall for minutes
        try:
            if sim("io", udid, "screenshot", str(path)).returncode == 0:
                return
        except subprocess.TimeoutExpired:
            pass
        time.sleep(15)
    raise RuntimeError(f"screenshot failed for {path}")


def settled(udid: str, path: Path, minimum: float = 4.0, maximum: float = 60.0) -> bool:
    time.sleep(minimum)
    deadline = time.monotonic() + maximum
    with tempfile.TemporaryDirectory() as tmp:
        previous = Path(tmp) / "previous.png"
        shot(udid, previous)
        while time.monotonic() < deadline:
            time.sleep(2)
            shot(udid, path)
            with Image.open(previous) as a, Image.open(path) as b:
                same = ImageChops.difference(a.convert("RGB"), b.convert("RGB")).getbbox() is None
                body = b.convert("RGB").crop((0, b.height // 6, b.width, b.height * 5 // 6))
                if same and max(ImageStat.Stat(body).var) >= 8.0:
                    return True
            previous.write_bytes(path.read_bytes())
    return False


def launch(udid: str, flow: str, language: str, region: str) -> None:
    args = [*FLOWS[flow], "-AppleLanguages", f"({language})", "-AppleLocale", region]
    error = ""
    for _ in range(5):
        try:
            r = sim("launch", "--terminate-running-process", udid, BUNDLE, *args, timeout=120)
            if r.returncode == 0:
                return
            error = r.stderr
        except subprocess.TimeoutExpired as e:
            error = str(e)
        time.sleep(15)
    raise RuntimeError(error)


def main() -> None:
    udid, root = sys.argv[1], Path(sys.argv[2])
    locales = list(LOCALES) if sys.argv[3] == "all" else sys.argv[3].split(",")
    only = sys.argv[5].split(",") if len(sys.argv) > 5 and sys.argv[4] == "--flows" else list(FLOWS)
    sim("status_bar", udid, "override", "--time", "9:41", "--batteryState", "charged", "--batteryLevel", "100",
        "--cellularBars", "4", "--wifiBars", "3")
    for locale in locales:
        language, region = LOCALES[locale]
        out = root / locale
        out.mkdir(parents=True, exist_ok=True)
        started = time.monotonic()
        for flow in only:
            if (out / f"{flow}.png").exists() and not (len(sys.argv) > 4):
                continue  # resume a stalled run
            launch(udid, flow, language, region)
            if not settled(udid, out / f"{flow}.png"):
                print(f"  warn: {locale}/{flow} never fully settled", flush=True)
        print(json.dumps({"locale": locale, "seconds": round(time.monotonic() - started)}), flush=True)


if __name__ == "__main__":
    main()
