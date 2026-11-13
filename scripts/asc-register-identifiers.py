#!/usr/bin/env python3
"""Register Ravel's bundle ID and turn on In-App Purchase. Safe to rerun."""
from __future__ import annotations

import sys
import urllib.parse
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import asc_lib

IDENTIFIERS = {
    "com.jackwallner.knit": ("Ravel", {"IN_APP_PURCHASE"}),
}


def ensure_bundle_id(client: asc_lib.ASCClient, identifier: str, name: str) -> dict:
    quoted = urllib.parse.quote(identifier, safe="")
    found = client.get(f"/bundleIds?filter[identifier]={quoted}").get("data", [])
    exact = [item for item in found if item["attributes"]["identifier"] == identifier]
    if exact:
        print(f"bundle id exists: {identifier}")
        return exact[0]
    created = client.post(
        "/bundleIds",
        {"data": {"type": "bundleIds", "attributes": {"identifier": identifier, "name": name, "platform": "IOS"}}},
    )["data"]
    print(f"bundle id created: {identifier}")
    return created


def ensure_capabilities(client: asc_lib.ASCClient, bundle_id: dict, required: set[str]) -> None:
    existing = asc_lib.list_all(client, f"/bundleIds/{bundle_id['id']}/bundleIdCapabilities")
    enabled = {item["attributes"]["capabilityType"] for item in existing}
    for capability in sorted(required - enabled):
        client.post(
            "/bundleIdCapabilities",
            {
                "data": {
                    "type": "bundleIdCapabilities",
                    "attributes": {"capabilityType": capability},
                    "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bundle_id["id"]}}},
                }
            },
        )
        print(f"  enabled {capability}")


def main() -> None:
    client = asc_lib.ASCClient.from_credentials()
    for identifier, (name, capabilities) in IDENTIFIERS.items():
        ensure_capabilities(client, ensure_bundle_id(client, identifier, name), capabilities)


if __name__ == "__main__":
    main()
