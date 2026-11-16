#!/usr/bin/env python3
"""Fit report: every header at the renderer's sizes, both devices. usage: fitcheck.py <headline-binary> [locale,...]"""
import json, subprocess, sys
from pathlib import Path
H = json.loads((Path(__file__).resolve().parent.parent / "copy/headers.json").read_text())
dev = {"iphone": (1320, 2868, 96, 142, 42, 540), "ipad": (2064, 2752, 90, 180, 186, 520)}
locs = sys.argv[2].split(",") if len(sys.argv) > 2 else list(H)
bad = 0
for d, (w, h, top, size, margin, limit) in dev.items():
    jobs = [{"text": t, "locale": l, "width": w, "height": h, "top": top, "limit": limit, "size": size, "minSize": 140, "margin": margin,
             "color": [0, 0, 0], "out": f"/tmp/claude-501/fit-{d}-{l}-{i}.png"} for l in locs for i, t in enumerate(H[l].values())]
    res = json.loads(subprocess.run([sys.argv[1]], input=json.dumps(jobs), text=True, capture_output=True, check=True).stdout)
    for j, r in zip(jobs, res):
        if not r["fits"] or r["bottom"] > limit - 6:
            bad += 1; print("NOFIT", d, j["locale"], j["text"])
    print(d, "min sizes by locale:", {l: min(r["size"] for j, r in zip(jobs, res) if j["locale"] == l) for l in locs})
print("failures", bad)
