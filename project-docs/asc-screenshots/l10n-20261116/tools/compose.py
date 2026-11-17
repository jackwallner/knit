#!/usr/bin/env python3
"""Compose the Ravel localized App Store sets with the shared renderer (~/ios/appstore-screenshots).

Background, device frame and layout come from configs/knit.json and configs/knit-ipad.json (the live
en-US sets). The header is drawn by headline (CoreText, see headline.swift) from copy/headers.json.

usage: compose.py <iphone|ipad> <raw-root> <headline-binary> <out-root> <locale,...|all>
  raw-root/<locale>/<flow>.png are the per-language captures (capture.py). out-root gets
  <locale>/<file>.png and provenance-<device>.json.
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

SHOTS = Path.home() / "ios" / "appstore-screenshots"
sys.path.insert(0, str(SHOTS))
from lib import render  # noqa: E402

HERE = Path(__file__).resolve().parent
COPY = json.loads((HERE.parent / "copy" / "headers.json").read_text())
CONFIGS = {"iphone": ("knit.json", "iphone_69"), "ipad": ("knit-ipad.json", "ipad_13")}
INK = (0x1C, 0x1A, 0x17)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def no_header(canvas, frame, theme, show_guides):
    return 0, {"header_only": True}


def compose(device: str, locale: str, raw_root: Path, headline: Path, out_root: Path) -> list[dict]:
    config_name, target = CONFIGS[device]
    manifest_path = SHOTS / "configs" / config_name
    manifest = json.loads(manifest_path.read_text())
    frames = manifest["sets"][0]["frames"]
    # ONLY=05-library.png recomposes one frame (a single recaptured flow); the rest stay as they are.
    only = [name for name in os.environ.get("ONLY", "").split(",") if name]
    frames = [f for f in frames if not only or f["filename"] in only]
    size = render.TARGETS[target]
    out = out_root / locale
    out.mkdir(parents=True, exist_ok=True)
    texts = {f["filename"]: f["header"] for f in frames} if locale == "en-US" else COPY[locale]
    jobs = []
    with tempfile.TemporaryDirectory() as tmp:
        for frame in frames:
            layout = frame["layout"]
            jobs.append({
                "text": texts[frame["filename"]], "locale": locale, "width": size[0], "height": size[1],
                "top": layout["header_top"], "limit": layout["phone_top"], "size": layout["header_size"], "minSize": layout["header_min_size"],
                "margin": layout.get("header_margin", round(size[0] * 0.09)), "color": list(INK),
                "out": f"{tmp}/{frame['filename']}",
            })
        measured = json.loads(subprocess.run([str(headline)], input=json.dumps(jobs), text=True,
                                             capture_output=True, check=True).stdout)
        records = []
        original = render.draw_header
        render.draw_header = no_header
        try:
            for frame, m in zip(frames, measured):
                if not m["fits"]:
                    raise RuntimeError(f"{device} {locale} {frame['filename']}: header needs more than two lines at {m['size']}")
                if m["bottom"] > frame["layout"]["phone_top"] - 6:
                    raise RuntimeError(f"{device} {locale} {frame['filename']}: header ink ends at {m['bottom']}, device starts at {frame['layout']['phone_top']}")
                raw = raw_root / locale / (frame["capture_flow"] + ".png")
                f = dict(frame, source=str(raw))
                image, _ = render.render_frame(manifest_path, manifest, f, target)
                with Image.open(m["out"]) as header:
                    image = Image.alpha_composite(image.convert("RGBA"), header.convert("RGBA")).convert("RGB")
                path = out / frame["filename"]
                image.save(path, format="PNG", optimize=True)
                records.append({"file": frame["filename"], "header": texts[frame["filename"]], "size": m["size"],
                                "lines": m["lines"], "source": raw.name, "source_sha256": sha(raw), "sha256": sha(path)})
        finally:
            render.draw_header = original
    return records


def main() -> None:
    device, raw_root, headline, out_root = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4])
    arg = sys.argv[5]
    locales = list(COPY) if arg == "all" else arg.split(",")
    provenance = {}
    for locale in locales:
        provenance[locale] = compose(device, locale, raw_root, headline, out_root)
        print(device, locale, [r["size"] for r in provenance[locale]], flush=True)
    target = out_root / f"provenance-{device}.json"
    previous = json.loads(target.read_text()) if target.exists() else {}
    target.write_text(json.dumps({**previous, **provenance}, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
    main()
