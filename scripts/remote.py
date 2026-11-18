#!/usr/bin/env python3
"""Control what the Ravel library shows, with no App Store update.

Everything here edits two files the app fetches from the site once a day (GitHub Pages serves `docs/`):
  docs/designs.json   seasonal and topical colorwork designs (checked by scripts/topical-check.sh)
  docs/trending.json  the Trending shelf: built-in designs by raw value, colorwork designs by id

  scripts/remote.py status                          what is live, scheduled, ended and featured
  scripts/remote.py publish <draft-id> [--starts D] [--ends D] [--free]
                                                    check a draft and move it into docs/designs.json
  scripts/remote.py pull <id>                       end a published design today (kept for its fixes)
  scripts/remote.py feature <id> <tag> [--at N]     put a design on the Trending shelf
  scripts/remote.py unfeature <id>                  take it off
  add --push to any change to commit and push it (phones pick it up within a day)

Publishing a design needs Jack's yes (.claude/rules/topical-loop.md). The onboarding trial's plan is
set in RevenueCat, not here: offering `default`, metadata `onboarding_plan` = "monthly" or "yearly".
"""
import argparse
import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DESIGNS = ROOT / "docs/designs.json"
TRENDING = ROOT / "docs/trending.json"
COLLECTION = ROOT / "Ravel/collection.json"
DRAFTS = ROOT / "project-docs/topical/drafts"


def load(path):
    return json.loads(path.read_text())


def save(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def built_in_designs():
    """Raw values of the Design enum, read from the source so the list never drifts."""
    source = (ROOT / "Shared/Patterns/Design.swift").read_text()
    body = source[source.index("enum Design:"):source.index("enum Shelf")]
    lines = re.findall(r"^    case ([a-zA-Z0-9, ]+)$", body, re.M)
    return {name.strip() for line in lines for name in line.split(",")}


def known_ids():
    ids = {r["id"] for r in load(COLLECTION)["designs"]}
    ids |= {r["id"] for r in load(DESIGNS)["designs"]}
    return ids


def resolvable(design_id):
    bare = design_id.removeprefix("topical.")
    return design_id in built_in_designs() or bare in known_ids()


def today():
    return datetime.date.today().isoformat()


def status(_):
    now = today()
    print("Designs on the site (docs/designs.json):")
    for r in load(DESIGNS)["designs"]:
        starts, ends = r.get("starts") or "-", r.get("ends") or "-"
        state = "scheduled" if starts != "-" and starts > now else "ended" if ends != "-" and ends <= now else "LIVE"
        free = " free" if r.get("free") else ""
        print(f"  {state:9} {r['id']:28} {r.get('tag', ''):12} {starts} to {ends}{free} rev {r.get('revision', 0)}")
    print("\nTrending shelf (docs/trending.json), after live designs and the collection's New ones:")
    for i, item in enumerate(load(TRENDING)["items"]):
        flag = "" if resolvable(item["design"]) else "   <- unknown, skipped by the app"
        print(f"  {i}. {item['design']:28} {item['tag']}{flag}")
    drafts = sorted(p.stem for p in DRAFTS.glob("*.json"))
    print("\nDrafts:", ", ".join(drafts) or "none")


def check(*files):
    result = subprocess.run([str(ROOT / "scripts/topical-check.sh"), *map(str, files)], cwd=ROOT)
    if result.returncode != 0:
        sys.exit("topical-check failed: nothing changed")


def publish(args):
    draft = DRAFTS / f"{args.id}.json"
    if not draft.exists():
        sys.exit(f"no draft {draft}")
    records = load(draft)["designs"]
    record = next((r for r in records if r["id"] == args.id), None) or sys.exit(f"{draft} has no record {args.id}")
    if args.starts:
        record["starts"] = args.starts
    if args.ends:
        record["ends"] = args.ends
    if args.free:
        record["free"] = True
    if not record.get("ends"):
        sys.exit("a published design needs an end date: --ends YYYY-MM-DD")
    listing = load(DESIGNS)
    old = next((r for r in listing["designs"] if r["id"] == args.id), None)
    if old:
        # A changed pattern raises its revision, so projects cast on from it are offered the fix.
        pattern = lambda r: {k: v for k, v in r.items() if k not in ("starts", "ends", "free", "tag", "title", "revision")}
        record["revision"] = old.get("revision", 0) + (1 if pattern(old) != pattern(record) else 0)
        listing["designs"] = [record if r["id"] == args.id else r for r in listing["designs"]]
    else:
        listing["designs"].append(record)
    staged = ROOT / "build/remote-designs.json"
    staged.parent.mkdir(exist_ok=True)
    save(staged, listing)
    check(staged)
    save(DESIGNS, listing)
    print(f"published {args.id}: {record.get('starts', 'now')} to {record['ends']}")
    finish(args, f"feat(topical): publish {args.id}")


def pull(args):
    listing = load(DESIGNS)
    record = next((r for r in listing["designs"] if r["id"] == args.id), None) or sys.exit(f"{args.id} is not published")
    # Never deleted: projects cast on from it still need the record to be offered corrections.
    record["ends"] = today()
    save(DESIGNS, listing)
    print(f"{args.id} ends today; it stays in the list for projects cast on from it")
    finish(args, f"chore(topical): end {args.id}")


def feature(args):
    if not resolvable(args.id):
        sys.exit(f"{args.id} is not a built-in design, a collection design or a published one")
    if len(args.tag) > 24:
        sys.exit("tags are at most 24 characters")
    listing = load(TRENDING)
    items = [i for i in listing["items"] if i["design"] != args.id]
    items.insert(min(args.at, len(items)) if args.at is not None else len(items), {"design": args.id, "tag": args.tag})
    listing["items"] = items
    save(TRENDING, listing)
    print(f"featured {args.id} as {args.tag!r}")
    finish(args, f"chore(trending): feature {args.id}")


def unfeature(args):
    listing = load(TRENDING)
    listing["items"] = [i for i in listing["items"] if i["design"] != args.id]
    save(TRENDING, listing)
    finish(args, f"chore(trending): unfeature {args.id}")


def finish(args, message):
    if not args.push:
        print("not pushed: rerun with --push, or commit docs/ yourself")
        return
    subprocess.run(["git", "add", str(DESIGNS), str(TRENDING)], cwd=ROOT, check=True)
    subprocess.run(["git", "commit", "-m", message], cwd=ROOT, check=True)
    subprocess.run(["git", "push"], cwd=ROOT, check=True)
    print("pushed: GitHub Pages serves it in a few minutes, phones fetch it within a day")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("status").set_defaults(run=status)
    p = commands.add_parser("publish")
    p.add_argument("id")
    p.add_argument("--starts")
    p.add_argument("--ends")
    p.add_argument("--free", action="store_true")
    p.set_defaults(run=publish)
    p = commands.add_parser("pull")
    p.add_argument("id")
    p.set_defaults(run=pull)
    p = commands.add_parser("feature")
    p.add_argument("id")
    p.add_argument("tag")
    p.add_argument("--at", type=int)
    p.set_defaults(run=feature)
    p = commands.add_parser("unfeature")
    p.add_argument("id")
    p.set_defaults(run=unfeature)
    for sub in commands.choices.values():
        sub.add_argument("--push", action="store_true")
    args = parser.parse_args()
    args.run(args)


if __name__ == "__main__":
    main()
