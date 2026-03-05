#!/usr/bin/env python3
"""
Upload localized App Store screenshots for a given version.
Usage: python3 upload_screenshots.py --version-id VERSION_ID [--dry-run]
"""
import subprocess
import sys
import os
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed

# ASC locale ID → our output folder name
# Collected from: asc localizations list --version VERSION_ID --paginate
LOCALE_MAP: dict[str, tuple[str, str]] = {
    "bb8eda2b-7c9a-4945-bd15-30450fb1353f": ("ru",      "ru"),
    "7a203ee7-4518-4d61-bf01-30fe2cc8b241": ("it",      "it"),
    "9b5a27a0-6529-49c2-801a-826b27affd15": ("es-MX",   "es-ES"),
    "3b0a6c83-448e-4bb3-94d7-20da6a722c13": ("id",      "id"),
    "8f9d02d9-b0a7-4efc-a375-013ce909a3a5": ("nl-NL",   "nl-NL"),
    "6eac9974-e878-4b00-8e27-22eef2a9a48d": ("sk",      "sk"),
    "dca92ae8-1eef-490c-996d-6d4ed109742b": ("fr-FR",   "fr-FR"),
    "6e15dc05-08fb-4ec7-b627-91e7e8b99e47": ("de-DE",   "de-DE"),
    "ea0963db-6656-42d5-a20a-a87b2ebadf6e": ("th",      "th"),
    "285431a8-e1a6-4ff3-ba76-ef98ea4481d9": ("ar-SA",   "ar"),
    "ebb8713e-bc8e-4271-8d3f-4f5579439719": ("uk",      "uk"),
    "978ec50e-98e5-435c-857f-2bf112a80073": ("da",      "da"),
    "0d742e4b-22f7-44a6-b490-761840467718": ("fi",      "fi"),
    "0c377204-b08f-4226-a81a-7011f6022c40": ("hi",      None),    # no Hindi screenshots
    "c6c9a244-1a07-4418-8511-7cd203ea9b18": ("hr",      "hr"),
    "a64f9fe7-77d1-4e2f-acff-b5fcf27d8dcf": ("he",      "he"),
    "f7bbaeee-146c-46cd-a2d7-3845989e539e": ("zh-Hans", "zh-Hans"),
    "b257f551-3865-425a-90d4-646775c6d585": ("ca",      "ca"),
    "88a21462-c68c-426e-8855-fda9420a0a16": ("pt-PT",   "pt-BR"), # closest match
    "8f1bff20-6936-47a5-818b-2acc3e2a4dfa": ("en-GB",   "en-US"),
    "bdabe9bf-8a8b-4e17-a527-18ecd808675a": ("ro",      "ro"),
    "56f179bb-2cd9-4832-bafe-b6c1c644ffd4": ("hu",      "hu"),
    "88520020-730b-4465-a3ae-317b6cb5daa3": ("fr-CA",   "fr-FR"), # closest match
    "e17619a0-8892-44af-a81f-9a9b142063df": ("es-ES",   "es-ES"),
    "eefe302b-e829-4ca3-b039-86718d05c4b1": ("ms",      "ms"),
    "13837bee-2af3-4556-b6b2-b1e3a2ad0749": ("pt-BR",   "pt-BR"),
    "d514c8c5-ed63-46ff-8f64-2b3621b6ca30": ("vi",      "vi"),
    "79def478-c9b1-4214-bd58-7675a98a1bff": ("sv",      "sv"),
    "a8b79847-18a7-4a42-9a2e-173f7e8536bc": ("en-AU",   "en-US"),
    "10c9eb6a-115d-4c8f-a022-b7a4e77a5b2d": ("cs",      "cs"),
    "5e50e177-c0f9-408d-a66a-ca261c94855f": ("en-CA",   "en-US"),
    "5e2f19eb-7a6c-4589-bfca-01963991d9f5": ("ja",      "ja"),
    "df140bd1-b7a5-414b-a4a0-2bf82b64f62c": ("zh-Hant", "zh-Hant"),
    "d4b6f905-fc26-45bd-8de7-75c1b3dafe8c": ("no",      "nb"),
    "4179acef-2f57-48e8-877c-81ea9d39e9bb": ("ko",      "ko"),
    "b53b3f96-6203-4314-959f-bd64e5000141": ("el",      "el"),
    "86428389-a5d6-4642-a61f-84093d0f70d2": ("pl",      "pl"),
    "d8f8e75a-ab28-435a-8e38-d6003f459f04": ("en-US",   "en-US"),
    "a455869f-6bfb-4379-baf5-a808775b35e0": ("tr",      "tr"),
}

# Screenshot filenames in display order
SCREENSHOTS = [
    "mix-sounds.png",
    "sleep-timer.png",
    "rain-variants.png",
]

DEVICE_TYPE = "IPHONE_67"   # 6.7" = 1320×2868 (iPhone 15/16 Pro Max)
OUTPUT_DIR  = os.path.join(os.path.dirname(__file__), "output")


def upload_one(loc_id: str, asc_locale: str, our_folder: str | None, dry_run: bool) -> list[str]:
    results = []
    if our_folder is None:
        return [f"SKIP  {asc_locale} (no screenshots)"]

    folder = os.path.join(OUTPUT_DIR, our_folder)
    if not os.path.isdir(folder):
        return [f"SKIP  {asc_locale} (folder {our_folder} missing)"]

    for filename in SCREENSHOTS:
        path = os.path.join(folder, filename)
        if not os.path.exists(path):
            results.append(f"SKIP  {asc_locale}/{filename} (file missing)")
            continue

        cmd = [
            "asc", "screenshots", "upload",
            "--version-localization", loc_id,
            "--path", path,
            "--device-type", DEVICE_TYPE,
        ]

        if dry_run:
            results.append(f"DRY   {asc_locale}/{filename}")
            continue

        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode == 0:
            results.append(f"OK    {asc_locale}/{filename}")
        else:
            err = (proc.stderr or proc.stdout).strip().splitlines()[0] if (proc.stderr or proc.stdout) else "unknown"
            results.append(f"ERROR {asc_locale}/{filename}: {err}")

    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Print what would be uploaded without doing it")
    parser.add_argument("--workers", type=int, default=6, help="Parallel upload threads (default 6)")
    args = parser.parse_args()

    total = sum(1 for _, folder in LOCALE_MAP.values() if folder is not None) * len(SCREENSHOTS)
    print(f"Uploading screenshots  device={DEVICE_TYPE}  locales={len(LOCALE_MAP)}  total≈{total}")
    if args.dry_run:
        print("(dry-run mode)")
    print()

    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {
            pool.submit(upload_one, loc_id, asc_locale, our_folder, args.dry_run): asc_locale
            for loc_id, (asc_locale, our_folder) in LOCALE_MAP.items()
        }
        for future in as_completed(futures):
            for line in future.result():
                print(line)

    print("\nDone.")


if __name__ == "__main__":
    main()
