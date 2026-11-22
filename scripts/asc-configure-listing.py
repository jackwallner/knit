#!/usr/bin/env python3
"""Configure the nonlocalized Ravel App Store listing fields: rights, copyright,
release type, categories, age rating, and the App Review contact and notes."""
from __future__ import annotations

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import asc_lib as A  # noqa: E402


BUNDLE_ID = "com.jackwallner.knit"
APP_NAME = "Ravel"
# Age-rating answers are copied from a live app's declaration, then the
# health answers are turned off below.
AGE_TEMPLATE_BUNDLE_ID = os.environ.get(
    "ASC_AGE_TEMPLATE_BUNDLE_ID", "com.jackwallner.vitals"
)
# One copy of the notes: the file fastlane also uploads.
REVIEW_NOTES = (Path(__file__).resolve().parent.parent / "fastlane/metadata/review_information/notes.txt").read_text().strip()


def review_phone() -> str:
    """The App Review contact number, which never belongs in a public repo."""
    value = os.environ.get("ASC_REVIEW_PHONE")
    if not value:
        raise SystemExit("error: set ASC_REVIEW_PHONE (source ~/.baseball_credentials)")
    return value.strip()


def main() -> None:
    """`--notes-only` updates the App Review contact and notes and leaves the
    rights, copyright and age rating alone."""
    if not REVIEW_NOTES.strip():
        raise SystemExit("error: write REVIEW_NOTES before configuring the listing")
    client = A.ASCClient.from_credentials()
    app = A.find_app(client, BUNDLE_ID)
    info = A.find_editable_app_info(client, app["id"])
    version = A.find_editable_version(client, app["id"])
    if not info or not version:
        raise SystemExit("error: Ravel needs an editable app info and version")
    if "--notes-only" not in sys.argv:
        configure_listing(client, app, info, version)
    configure_review(client, version)
    print(f"configured {APP_NAME} ({app['id']})")


def configure_listing(client: A.ASCClient, app: dict, info: dict, version: dict) -> None:

    client.patch(
        f"/apps/{app['id']}",
        {
            "data": {
                "type": "apps",
                "id": app["id"],
                "attributes": {
                    "contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT",
                },
            }
        },
    )
    client.patch(
        f"/appStoreVersions/{version['id']}",
        {
            "data": {
                "type": "appStoreVersions",
                "id": version["id"],
                "attributes": {
                    "copyright": "2026 Jack Wallner",
                    "releaseType": "MANUAL",
                },
            }
        },
    )
    client.patch(
        f"/appInfos/{info['id']}",
        {
            "data": {
                "type": "appInfos",
                "id": info["id"],
                "relationships": {
                    "primaryCategory": {"data": {"type": "appCategories", "id": "LIFESTYLE"}},
                    "secondaryCategory": {"data": {"type": "appCategories", "id": "PRODUCTIVITY"}},
                },
            }
        },
    )
    age = client.get(f"/appInfos/{info['id']}/ageRatingDeclaration")["data"]
    template_app = A.find_app(client, AGE_TEMPLATE_BUNDLE_ID)
    template_info = A.find_editable_app_info(client, template_app["id"])
    template_age = client.get(
        f"/appInfos/{template_info['id']}/ageRatingDeclaration"
    )["data"]["attributes"]
    attrs = {key: value for key, value in template_age.items() if value is not None}
    attrs.pop("ageRatingOverride", None)
    attrs.update(
        {
            "healthOrWellnessTopics": False,
            "medicalOrTreatmentInformation": "NONE",
            "alcoholTobaccoOrDrugUseOrReferences": "NONE",
        }
    )
    client.patch(
        f"/ageRatingDeclarations/{age['id']}",
        {
            "data": {
                "type": "ageRatingDeclarations",
                "id": age["id"],
                "attributes": attrs,
            }
        },
    )



def configure_review(client: A.ASCClient, version: dict) -> None:
    review = client.get(f"/appStoreVersions/{version['id']}/appStoreReviewDetail").get("data")
    attributes = {
        "contactFirstName": "Jack",
        "contactLastName": "Wallner",
        "contactPhone": review_phone(),
        "contactEmail": "jackwallner+rv@gmail.com",
        "demoAccountRequired": False,
        "notes": REVIEW_NOTES,
    }
    if review:
        client.patch(
            f"/appStoreReviewDetails/{review['id']}",
            {
                "data": {
                    "type": "appStoreReviewDetails",
                    "id": review["id"],
                    "attributes": attributes,
                }
            },
        )
    else:
        client.post(
            "/appStoreReviewDetails",
            {
                "data": {
                    "type": "appStoreReviewDetails",
                    "attributes": attributes,
                    "relationships": {
                        "appStoreVersion": {
                            "data": {"type": "appStoreVersions", "id": version["id"]}
                        }
                    },
                }
            },
        )


if __name__ == "__main__":
    main()
