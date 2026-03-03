#!/usr/bin/env python3.14
"""
Capture localized App Store screenshots from iOS Simulator.
Launches the app in each locale, taps through 3 screenshot scenarios,
and saves PNGs to public/screenshots/{locale}/.

Usage:
    python3.14 capture_localized.py             # all 32 locales
    python3.14 capture_localized.py en-US       # single locale
    python3.14 capture_localized.py ja ko zh-Hans  # multiple locales
"""

import subprocess
import sys
import time
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────────
UDID       = "E07C37DD-8D4D-492A-9155-26565D58A8AE"
BUNDLE_ID  = "ruslan.whiteNoise.WhiteNoise"
SCRIPT_DIR = Path(__file__).parent
OUT_DIR    = SCRIPT_DIR / "public" / "screenshots"

# UIKit coordinates (440×956 canvas, iPhone 16 Pro Max)
TAP_RAIN      = (80,  140)   # Rain card center
TAP_BONFIRE   = (220, 140)   # Bonfire card center
TAP_FOREST    = (80,  275)   # Forest card center
TAP_PLAY      = (220, 890)   # Play/Pause button
TAP_TIMER     = (141, 890)   # Timer button
TAP_CLOSE_X   = (415, 483)   # Timer modal close button (×)
TAP_VARIANT   = (80,  196)   # Rain variant popup button
TAP_DISMISS   = (220, 600)   # Dismiss variant picker (outside area)

# Locale → (AppleLanguages code, AppleLocale code)
LOCALES = {
    "en-US":    ("en",      "en_US"),
    "de-DE":    ("de",      "de_DE"),
    "fr-FR":    ("fr",      "fr_FR"),
    "es-ES":    ("es",      "es_ES"),
    "it":       ("it",      "it_IT"),
    "pt-BR":    ("pt-BR",   "pt_BR"),
    "ja":       ("ja",      "ja_JP"),
    "ko":       ("ko",      "ko_KR"),
    "zh-Hans":  ("zh-Hans", "zh_CN"),
    "zh-Hant":  ("zh-Hant", "zh_TW"),
    "nl-NL":    ("nl",      "nl_NL"),
    "ru":       ("ru",      "ru_RU"),
    "uk":       ("uk",      "uk_UA"),
    "tr":       ("tr",      "tr_TR"),
    "ar":       ("ar",      "ar_SA"),
    "th":       ("th",      "th_TH"),
    "vi":       ("vi",      "vi_VN"),
    "pl":       ("pl",      "pl_PL"),
    "sv":       ("sv",      "sv_SE"),
    "da":       ("da",      "da_DK"),
    "nb":       ("nb",      "nb_NO"),
    "fi":       ("fi",      "fi_FI"),
    "hu":       ("hu",      "hu_HU"),
    "ro":       ("ro",      "ro_RO"),
    "sk":       ("sk",      "sk_SK"),
    "ca":       ("ca",      "ca_ES"),
    "ms":       ("ms",      "ms_MY"),
    "hr":       ("hr",      "hr_HR"),
    "el":       ("el",      "el_GR"),
    "cs":       ("cs",      "cs_CZ"),
    "id":       ("id",      "id_ID"),
    "he":       ("he",      "he_IL"),
}

# ── Helpers ───────────────────────────────────────────────────────────────────
def run(*cmd: str, check=True) -> subprocess.CompletedProcess:
    return subprocess.run(list(cmd), capture_output=True, text=True, check=check)


_IDB_TAP_SCRIPT = """
import asyncio, sys
orig = asyncio.get_event_loop
def p():
    try: return orig()
    except RuntimeError:
        l = asyncio.new_event_loop(); asyncio.set_event_loop(l); return l
asyncio.get_event_loop = p
sys.argv = ['idb', 'ui', 'tap', '{x}', '{y}', '--udid', '{udid}']
from idb.cli.main import main; main()
"""

def idb_tap(x: int, y: int) -> bool:
    """Send a UIKit-coordinate tap via idb (subprocess per call to avoid closed event loop)."""
    script = _IDB_TAP_SCRIPT.format(x=x, y=y, udid=UDID)
    result = subprocess.run(
        [sys.executable, "-c", script],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        print(f"    idb_tap({x},{y}) failed: {result.stderr[:80]}", file=sys.stderr)
    return result.returncode == 0


def screenshot(path: Path) -> None:
    run("xcrun", "simctl", "io", UDID, "screenshot", str(path))


def launch(lang_code: str, locale_code: str) -> None:
    """Terminate existing instance, then launch with locale args."""
    run("xcrun", "simctl", "terminate", UDID, BUNDLE_ID, check=False)
    time.sleep(0.5)
    run(
        "xcrun", "simctl", "launch", UDID, BUNDLE_ID,
        "-AppleLanguages", f"({lang_code})",
        "-AppleLocale", locale_code,
    )
    time.sleep(3.5)   # wait for app to fully load


def capture_locale(locale: str, lang_code: str, locale_code: str, is_first: bool) -> bool:
    out = OUT_DIR / locale
    out.mkdir(parents=True, exist_ok=True)

    print(f"  [{locale}] launching ({lang_code}/{locale_code})…")
    launch(lang_code, locale_code)

    # ── Screenshot 01: main grid with multiple sounds playing ──────────────
    if is_first:
        # Activate 3 sounds on fresh install
        idb_tap(*TAP_RAIN)
        time.sleep(0.2)
        idb_tap(*TAP_BONFIRE)
        time.sleep(0.2)
        idb_tap(*TAP_FOREST)
        time.sleep(0.2)
    # After relaunch UserDefaults preserves which cards are selected;
    # just tap Play to start playback
    idb_tap(*TAP_PLAY)
    time.sleep(1.2)
    screenshot(out / "01_main_grid_playing.png")
    print(f"  [{locale}] ✓ 01_main_grid_playing.png")

    # ── Screenshot 02: sleep timer modal ──────────────────────────────────
    idb_tap(*TAP_TIMER)
    time.sleep(1.5)
    screenshot(out / "02_timer_modal.png")
    print(f"  [{locale}] ✓ 02_timer_modal.png")

    # Dismiss timer modal (tap the × button)
    idb_tap(*TAP_CLOSE_X)
    time.sleep(0.8)

    # ── Screenshot 03: rain variant picker open ────────────────────────────
    idb_tap(*TAP_VARIANT)
    time.sleep(1.5)
    screenshot(out / "03_variant_picker_rain.png")
    print(f"  [{locale}] ✓ 03_variant_picker_rain.png")

    # Dismiss variant picker
    idb_tap(*TAP_DISMISS)
    time.sleep(0.5)

    return True


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    targets = sys.argv[1:] if len(sys.argv) > 1 else list(LOCALES.keys())

    unknown = [t for t in targets if t not in LOCALES]
    if unknown:
        print(f"Unknown locales: {unknown}", file=sys.stderr)
        sys.exit(1)

    print(f"Capturing {len(targets)} locale(s): {', '.join(targets)}\n")

    ok, failed = 0, []
    for i, locale in enumerate(targets):
        lang_code, locale_code = LOCALES[locale]
        try:
            capture_locale(locale, lang_code, locale_code, is_first=(i == 0))
            ok += 1
        except Exception as e:
            failed.append(locale)
            print(f"  [{locale}] ✗ {e}", file=sys.stderr)

    print(f"\nDone: {ok * 3} screenshots for {ok}/{len(targets)} locale(s)")
    if failed:
        print(f"Failed: {', '.join(failed)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
