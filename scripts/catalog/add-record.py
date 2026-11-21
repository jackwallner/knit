#!/usr/bin/env python3
"""Appends a design record to the bundled collection, Ravel/collection.json, in the file's own format.
   python3 scripts/catalog/add-record.py '<record json>'
Replaces a record with the same id. Check it after with scripts/topical-check.sh Ravel/collection.json.
"""
import json
import sys
from pathlib import Path

PATH = Path(__file__).resolve().parents[2] / "Ravel" / "collection.json"
record = json.loads(sys.argv[1])
data = json.loads(PATH.read_text())
data["designs"] = [r for r in data["designs"] if r["id"] != record["id"]] + [record]
PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
print(f"{record['id']}: {len(data['designs'])} records")
