#!/usr/bin/env python3
"""Create the Ravel Patterns Lifetime non-consumable in App Store Connect, with regional prices. Safe to rerun.

Companion to `asc-setup-subscriptions.py`, which creates the monthly and yearly subscriptions.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import asc_lib

BUNDLE = "com.jackwallner.knit"
PRODUCT_ID = "com.jackwallner.knit.lifetime"
# App Store Connect's internal reference name is immutable after creation.
PRODUCT_REFERENCE_NAME = "Ravel Patterns Lifetime"
PRODUCT_DISPLAY_NAME = "Patterns Lifetime"
PRODUCT_DESCRIPTION = "Every pattern, for good. One payment."
PRICE = "79.99"
# Regional prices, the fleet tiers scaled to this price point: USD targets.
TIERS: dict[str, float] = {
    **{t: 25.99 for t in ["IND", "PAK", "BGD", "IDN", "VNM", "PHL", "EGY", "NGA"]},
    **{t: 41.99 for t in ["TUR", "BRA", "MEX", "COL", "CHL", "THA", "MYS", "POL", "HUN", "ROU", "ZAF", "RUS"]},
    **{t: 63.99 for t in ["SAU", "ARE", "CZE", "CHN"]},
}
FX = {
    "IND": .012, "PAK": .0036, "BGD": .0082, "IDN": .000062, "VNM": .0000395, "PHL": .0173,
    "EGY": .020, "NGA": .00065, "TUR": .029, "BRA": .20, "MEX": .049, "COL": .00024,
    "CHL": .0011, "THA": .029, "MYS": .22, "POL": .25, "HUN": .0028, "ROU": .22,
    "ZAF": .055, "RUS": .011, "SAU": .27, "ARE": .27, "CZE": .044, "CHN": .14,
}

V1 = "https://api.appstoreconnect.apple.com/v1"
V2 = "https://api.appstoreconnect.apple.com/v2"


def main() -> None:
    client = asc_lib.ASCClient.from_credentials()
    app_id = asc_lib.find_app(client, BUNDLE)["id"]
    print(f"app {app_id}")

    territories = [item["id"] for item in asc_lib.list_all(client, "/territories?limit=200")]
    iaps = asc_lib.list_all(client, f"/apps/{app_id}/inAppPurchasesV2")
    iap = next((item for item in iaps if item["attributes"].get("productId") == PRODUCT_ID), None)

    if not iap:
        try:
            asc_lib.API = V2
            iap = client.post(
                "/inAppPurchases",
                {
                    "data": {
                        "type": "inAppPurchases",
                        "attributes": {
                            "name": PRODUCT_REFERENCE_NAME,
                            "productId": PRODUCT_ID,
                            "inAppPurchaseType": "NON_CONSUMABLE",
                            "reviewNote": "One-time purchase that unlocks the Ravel pattern library for good: knitting patterns written to the knitter's own measurements and gauge. Projects, the row counter, the knitter's own PDFs and the stash are free.",
                        },
                        "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
                    }
                },
            )["data"]
        finally:
            asc_lib.API = V1
        print("lifetime IAP created")
    iap_id = iap["id"]

    try:
        asc_lib.API = V2
        existing_locs = asc_lib.list_all(client, f"/inAppPurchases/{iap_id}/inAppPurchaseLocalizations")
    finally:
        asc_lib.API = V1

    locales = ["en-US"]
    by_locale = {item["attributes"].get("locale"): item for item in existing_locs}
    for locale in locales:
        product_path = asc_lib.META / locale / "products.json"
        product = json.loads(product_path.read_text()) if product_path.exists() else {}
        name = product.get("lifetime_name") or PRODUCT_DISPLAY_NAME
        description = product.get("lifetime_desc") or PRODUCT_DESCRIPTION
        existing = by_locale.get(locale)
        if existing:
            attrs = existing.get("attributes", {})
            if attrs.get("name") != name or attrs.get("description") != description:
                client.patch(
                    f"/inAppPurchaseLocalizations/{existing['id']}",
                    {
                        "data": {
                            "type": "inAppPurchaseLocalizations",
                            "id": existing["id"],
                            "attributes": {"name": name, "description": description},
                        }
                    },
                )
            continue
        client.post(
            "/inAppPurchaseLocalizations",
            {
                "data": {
                    "type": "inAppPurchaseLocalizations",
                    "attributes": {"locale": locale, "name": name, "description": description},
                    "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}},
                }
            },
        )
    print(f"IAP localizations set for {len(locales)} locales")

    try:
        asc_lib.API = V2
        client.get(f"/inAppPurchases/{iap_id}/iapPriceSchedule")
        schedule_exists = True
    except RuntimeError:
        schedule_exists = False
    finally:
        asc_lib.API = V1

    try:
        asc_lib.API = V2
        points = asc_lib.list_all(client, f"/inAppPurchases/{iap_id}/pricePoints?filter[territory]=USA&limit=200")
    finally:
        asc_lib.API = V1
    point = next((item for item in points if item["attributes"].get("customerPrice") == PRICE), None)
    if not point:
        raise SystemExit(f"error: USA price point {PRICE} unavailable")
    chosen = {"USA": point["id"]}
    for territory, target in TIERS.items():
        try:
            asc_lib.API = V2
            local = asc_lib.list_all(client, f"/inAppPurchases/{iap_id}/pricePoints?filter[territory]={territory}&limit=200")
        finally:
            asc_lib.API = V1
        if not local:
            print(f"no price points for {territory}, using Apple's equalized price")
            continue
        ranked = sorted((float(p["attributes"]["customerPrice"]) * FX[territory], p["id"]) for p in local)
        eligible = [item for item in ranked if item[0] <= target]
        chosen[territory] = (eligible[-1] if eligible else ranked[0])[1]
    rows = [
        {
            "type": "inAppPurchasePrices",
            "id": f"${{price{index}}}",
            "attributes": {"startDate": None},
            "relationships": {"inAppPurchasePricePoint": {"data": {"type": "inAppPurchasePricePoints", "id": point_id}}},
        }
        for index, point_id in enumerate(chosen.values())
    ]
    client.post(
        "/inAppPurchasePriceSchedules",
        {
            "data": {
                "type": "inAppPurchasePriceSchedules",
                "relationships": {
                    "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                    "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                    "manualPrices": {"data": [{"type": row["type"], "id": row["id"]} for row in rows]},
                },
            },
            "included": rows,
        },
    )
    print(f"IAP price {'updated' if schedule_exists else 'set'} ${PRICE}, {len(rows) - 1} regional prices")

    try:
        asc_lib.API = V2
        client.get(f"/inAppPurchases/{iap_id}/inAppPurchaseAvailability")
        print("IAP availability exists")
    except RuntimeError:
        asc_lib.API = V1
        client.post(
            "/inAppPurchaseAvailabilities",
            {
                "data": {
                    "type": "inAppPurchaseAvailabilities",
                    "attributes": {"availableInNewTerritories": True},
                    "relationships": {
                        "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                        "availableTerritories": {"data": [{"type": "territories", "id": item} for item in territories]},
                    },
                }
            },
        )
        print(f"IAP available in {len(territories)} territories")
    finally:
        asc_lib.API = V1


if __name__ == "__main__":
    main()
