#!/usr/bin/env python3
"""
Upload localized App Store screenshots for a given version.

Usage:
    python3 upload_screenshots.py                                  # iPhone 6.7"
    python3 upload_screenshots.py --device-type IPAD_PRO_3GEN_129 # iPad Pro 13"
    python3 upload_screenshots.py --dry-run                        # preview only

Device types:
    IPHONE_67           6.7" iPhone (iPhone 15/16 Pro Max)  → output/<locale>/
    IPAD_PRO_3GEN_129   iPad Pro 13" (M4)                   → output/ipad/<locale>/
"""
import subprocess
import sys
import os
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed

# ASC locale ID → (asc-locale, our-output-folder)
# LOCALE_MAP is version-specific. These UUIDs are localization IDs for:
#   App: WhiteNoise  |  Version: 1.4.4  |  Platform: IOS
# They MUST be regenerated for every new App Store version before uploading.
# Regenerate with:
#   asc localizations list --version <VERSION_ID> --output json
# then rebuild this map from the returned 'id' fields.
LOCALE_MAP: dict[str, tuple[str, str]] = {
    "444d36d0-71b6-4f61-8105-c7bca3eec569": ("ru",      "ru"),
    "559c2503-9ffa-4ea0-b3b7-8949b8db09cb": ("it",      "it"),
    "731dd44c-e823-4a92-8332-6a28db0e32b8": ("es-MX",   "es-ES"),
    "8efba89e-06c2-4708-8224-cf36a8b75eab": ("id",      "id"),
    "cb696d9f-9f6e-47fa-be32-cc2d5cc56682": ("nl-NL",   "nl-NL"),
    "3427ccab-91ac-4a76-b413-544d8671e56a": ("sk",      "sk"),
    "41513107-b45a-4aaa-a37a-7bd9b52fbd2d": ("fr-FR",   "fr-FR"),
    "400e2587-111f-40e9-80ce-ca92eeba6e49": ("de-DE",   "de-DE"),
    "c7c5e908-36ac-4b56-8830-afcedcf434d7": ("th",      "th"),
    "7f9cb47c-8e72-413a-9853-86075259afff": ("ar-SA",   "ar"),
    "4c5288b9-23b4-4452-8531-c6d681ec564f": ("uk",      "uk"),
    "9a742e07-90aa-473b-b0d4-a55d50c7d8ae": ("da",      "da"),
    "1fd70baa-6126-4e05-a925-7bd8c554293f": ("fi",      "fi"),
    "4a5c925d-0429-4e10-9141-21acf3d166e5": ("hi",      None),    # no Hindi screenshots
    "bd366511-5a35-4fbf-b524-c50d7b1f5790": ("hr",      "hr"),
    "bb343563-1f7c-4d57-909b-1cd3d7d44a59": ("he",      "he"),
    "1c9d20c2-4fb1-4c0a-9820-820100743aa9": ("zh-Hans", "zh-Hans"),
    "782525f6-a531-4c25-af22-96692e062e10": ("ca",      "ca"),
    "561bb652-03e1-430a-a58d-2dabee9b8b1f": ("pt-PT",   "pt-BR"), # closest match
    "a203c6a9-5be8-42a0-ab7f-da4f346b014e": ("en-GB",   "en-US"),
    "bc1956c4-0faa-4718-a1ad-7183c62c25db": ("ro",      "ro"),
    "5dcb71c3-5ae2-4e5c-a0cc-f468e0973c01": ("hu",      "hu"),
    "4159c406-d65c-46f7-9f88-f25a75cf31b0": ("fr-CA",   "fr-FR"), # closest match
    "c20a845d-7013-40e1-9617-d9fea1e6d640": ("es-ES",   "es-ES"),
    "fbb45bae-5d10-4460-900f-a2df7c4a86b7": ("ms",      "ms"),
    "328302a0-26e4-4f4a-9a8f-4b4c639b30b3": ("pt-BR",   "pt-BR"),
    "1d2b3c4b-f0b2-41d0-99ee-bffe308e94c1": ("vi",      "vi"),
    "6e6a76f3-b1a6-4b74-80ff-10701069266c": ("sv",      "sv"),
    "69cf3d03-5014-4c0f-a43e-c36200cd3576": ("en-AU",   "en-US"),
    "c3cd2048-07b9-48eb-b555-6a2ff5b34e17": ("cs",      "cs"),
    "6e5dc6f1-9561-4cb5-8cf5-c96696b2dce4": ("en-CA",   "en-US"),
    "a9eccd93-6341-46a9-8b0e-ba5d57581ddb": ("ja",      "ja"),
    "3578d6b4-198a-41ec-b426-75ecc20ce1b2": ("zh-Hant", "zh-Hant"),
    "9b30d0db-e96e-4b68-bf48-f4d4b97c8d8b": ("no",      "nb"),
    "a575804d-a7fa-4889-8705-2df81812f264": ("ko",      "ko"),
    "6c54e23c-e0e4-48c5-858d-d6cbb8fa6aa3": ("el",      "el"),
    "eebdab3e-dc3b-4603-9b45-8d27c94c68f0": ("pl",      "pl"),
    "1b0f4d6e-4233-45e3-9e31-3a6051f5e430": ("en-US",   "en-US"),
    "54bf1736-273c-47f6-a046-b776975ce5d9": ("tr",      "tr"),
}

# Screenshot filenames in display order
SCREENSHOTS = [
    "mix-sounds.png",
    "sleep-timer.png",
    "rain-variants.png",
]

DEVICE_CONFIGS = {
    "IPHONE_67":          "output",        # iPhone 6.7" → output/<locale>/
    "IPAD_PRO_3GEN_129":  "output/ipad",   # iPad Pro 13" → output/ipad/<locale>/
}

SCRIPT_DIR = os.path.dirname(__file__)


def upload_one(loc_id: str, asc_locale: str, our_folder: str | None,
               device_type: str, output_root: str, dry_run: bool) -> list[str]:
    results = []
    if our_folder is None:
        return [f"SKIP  {asc_locale} (no screenshots)"]

    folder = os.path.join(SCRIPT_DIR, output_root, our_folder)
    if not os.path.isdir(folder):
        return [f"WARN  {asc_locale} (folder {output_root}/{our_folder} missing — run render.mjs first)"]

    for filename in SCREENSHOTS:
        path = os.path.join(folder, filename)
        if not os.path.exists(path):
            results.append(f"WARN  {asc_locale}/{filename} (file missing)")
            continue

        cmd = [
            "asc", "screenshots", "upload",
            "--version-localization", loc_id,
            "--path", path,
            "--device-type", device_type,
        ]

        if dry_run:
            results.append(f"DRY   {asc_locale}/{filename}  [{device_type}]")
            continue

        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode == 0:
            results.append(f"OK    {asc_locale}/{filename}")
        else:
            err = (proc.stderr or proc.stdout).strip() or "unknown"
            results.append(f"ERROR {asc_locale}/{filename}: {err}")

    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--device-type", default="IPHONE_67",
                        choices=list(DEVICE_CONFIGS.keys()),
                        help="ASC screenshot device type (default: IPHONE_67)")
    parser.add_argument("--dry-run", action="store_true", help="Print what would be uploaded without doing it")
    parser.add_argument("--workers", type=int, default=6, help="Parallel upload threads (default 6)")
    args = parser.parse_args()

    output_root = DEVICE_CONFIGS[args.device_type]
    total = sum(1 for _, folder in LOCALE_MAP.values() if folder is not None) * len(SCREENSHOTS)
    print(f"Uploading screenshots  device={args.device_type}  output={output_root}  locales={len(LOCALE_MAP)}  total≈{total}")
    if args.dry_run:
        print("(dry-run mode)")
    print()

    error_count = 0
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {
            pool.submit(upload_one, loc_id, asc_locale, our_folder,
                        args.device_type, output_root, args.dry_run): asc_locale
            for loc_id, (asc_locale, our_folder) in LOCALE_MAP.items()
        }
        for future in as_completed(futures):
            locale = futures[future]
            try:
                for line in future.result():
                    print(line)
                    if line.startswith("ERROR"):
                        error_count += 1
            except Exception as exc:
                print(f"ERROR  {locale}: unexpected exception: {exc}")
                error_count += 1

    if error_count > 0:
        print(f"\n{error_count} upload(s) failed.")
        sys.exit(1)
    print("\nDone.")


if __name__ == "__main__":
    main()
