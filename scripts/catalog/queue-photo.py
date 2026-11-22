#!/usr/bin/env python3
"""Queues a sample photo prompt: python3 scripts/catalog/queue-photo.py <id> <camera> "<scene>" "<subject>"

Adds the subject and the shot to project-docs/sample-photos, in the files' own format. Nothing is generated.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "project-docs" / "sample-photos"
ident, camera, scene, subject = sys.argv[1:5]
subjects = json.loads((ROOT / "subjects.json").read_text())
shots = json.loads((ROOT / "shots.json").read_text())
if camera not in shots["cameras"]:
    sys.exit(f"unknown camera {camera}: {', '.join(shots['cameras'])}")
subjects[ident] = subject
shots["shots"][ident] = {"camera": camera, "scene": scene}
(ROOT / "subjects.json").write_text(json.dumps(subjects, indent=1, ensure_ascii=False))
(ROOT / "shots.json").write_text(json.dumps(shots, indent=1, ensure_ascii=False))
print(f"queued {ident}")
