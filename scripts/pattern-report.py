#!/usr/bin/env python3
"""Decode a Ravel pattern report and print what to rebuild.

Usage: scripts/pattern-report.py "<whole email text or the ravel-report line>"
Triage steps: .claude/rules/pattern-reports.md
"""
import base64
import json
import re
import sys


def main() -> int:
    text = " ".join(sys.argv[1:]) or sys.stdin.read()
    match = re.search(r"ravel-report ([A-Za-z0-9+/=]+)", text)
    if not match:
        print("no ravel-report line found", file=sys.stderr)
        return 1
    code = json.loads(base64.b64decode(match.group(1)))
    print(json.dumps(code, indent=2, sort_keys=True))
    measures = ", ".join(f'"{k}": {v}' for k, v in sorted((code.get("measures") or {}).items()))
    gauge = code.get("gauge") or {}
    print("\nRegression test (RavelTests/ReportedPatternsTests.swift):")
    print(f'    let plan = Design.{code["design"]}.plan(measures: [{measures}], '
          f'gauge: Gauge(stitches: {gauge.get("stitches")}, rows: {gauge.get("rows")}))')
    print(f'    // reported at step {code["step"] + 1}, row {code["row"] + 1} (tap {code["taps"]}), app {code["app"]}, revision {code.get("revision")}')
    return 0


if __name__ == "__main__":
    sys.exit(main())
