#!/usr/bin/env bash
# WhiteNoise Release Pipeline
#
# Steps: version bump → what's new → archive → export+upload
#
# Usage:
#   bash scripts/release.sh
#   bash scripts/release.sh --skip-archive   # re-use existing archive
#   bash scripts/release.sh --skip-upload    # archive only, no upload
#   bash scripts/release.sh --dry-run        # print commands without running
#
# Prerequisites:
#   brew install chargepoint/asc-tools/asc   (or: npm install -g @asc-tools/cli)
#   asc auth status                          # verify auth is configured
#   ASC_APP_ID env var (or will be prompted)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT="$ROOT_DIR/WhiteNoise.xcodeproj"
SCHEME="WhiteNoise"
ARCHIVE_PATH="$ROOT_DIR/build/WhiteNoise.xcarchive"
EXPORT_PATH="$ROOT_DIR/build/export"
EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions.plist"
PBXPROJ="$PROJECT/project.pbxproj"

# ── flags ────────────────────────────────────────────────────────────────────
DRY_RUN=false
SKIP_ARCHIVE=false
SKIP_UPLOAD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)      DRY_RUN=true ;;
        --skip-archive) SKIP_ARCHIVE=true ;;
        --skip-upload)  SKIP_UPLOAD=true ;;
        *) echo "Unknown flag: $1"; exit 1 ;;
    esac
    shift
done

run() {
    if $DRY_RUN; then echo "[dry-run] $*"; else "$@"; fi
}

# ── check prerequisites ───────────────────────────────────────────────────────
if ! command -v asc &>/dev/null; then
    echo "Error: asc CLI not found."
    echo "Install: brew install chargepoint/asc-tools/asc"
    echo "         or: npm install -g @asc-tools/cli"
    exit 1
fi

# ── step 1: version bump ──────────────────────────────────────────────────────
echo ""
echo "── Step 1: Version Bump ─────────────────────────────────────────────────"

CURRENT_VERSION=$(grep -m1 'MARKETING_VERSION' "$PBXPROJ" | sed 's/.*= \(.*\);/\1/' | tr -d '[:space:]')
CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION' "$PBXPROJ" | sed 's/.*= \(.*\);/\1/' | tr -d '[:space:]')

if [[ -z "$CURRENT_VERSION" || -z "$CURRENT_BUILD" ]]; then
    echo "Error: Could not read version or build number from $PBXPROJ"
    exit 1
fi

echo "Current version: $CURRENT_VERSION (build $CURRENT_BUILD)"
echo ""
read -rp "New marketing version (e.g. 1.4.4): " NEW_VERSION
read -rp "New build number [${CURRENT_BUILD}+1 = $((CURRENT_BUILD + 1))]: " NEW_BUILD
NEW_BUILD="${NEW_BUILD:-$((CURRENT_BUILD + 1))}"

if [[ -z "$NEW_VERSION" ]]; then
    echo "Error: version is required"; exit 1
fi

echo "Bumping to $NEW_VERSION (build $NEW_BUILD)..."
# Escape dots so sed treats them as literals, not regex wildcards
ESCAPED_CURRENT_VERSION="${CURRENT_VERSION//./\\.}"
run sed -i '' \
    "s/MARKETING_VERSION = ${ESCAPED_CURRENT_VERSION};/MARKETING_VERSION = ${NEW_VERSION};/g" \
    "$PBXPROJ"
run sed -i '' \
    "s/CURRENT_PROJECT_VERSION = ${CURRENT_BUILD};/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" \
    "$PBXPROJ"
echo "Done."

# ── step 2: what's new ───────────────────────────────────────────────────────
echo ""
echo "── Step 2: What's New ───────────────────────────────────────────────────"
echo "Enter release notes for en-US (press Enter twice to finish):"
WHATS_NEW=""
while IFS= read -r line; do
    [[ -z "$line" && -n "$WHATS_NEW" ]] && break
    WHATS_NEW+="${line}"$'\n'
done
WHATS_NEW="${WHATS_NEW%$'\n'}"  # trim trailing newline

# Resolve app ID
if [[ -z "${ASC_APP_ID:-}" ]]; then
    if $DRY_RUN; then
        echo "[dry-run] ASC_APP_ID not set — set it before running for real"
        ASC_APP_ID="DRY_RUN_APP_ID"
        export ASC_APP_ID
    else
        echo ""
        echo "ASC_APP_ID not set. Looking up app..."
        asc apps --output table
        read -rp "Enter App ID from the list above: " ASC_APP_ID
        export ASC_APP_ID
    fi
fi

if $DRY_RUN; then
    echo "[dry-run] asc versions create/set — skipping in dry-run mode"
    VERSION_ID="DRY_RUN_VERSION_ID"
else
    echo ""
    echo "Creating App Store version $NEW_VERSION..."
    # Create version; fall back to fetching existing if it already exists
    create_err=$(mktemp)
    VERSION_JSON=$(asc versions create \
        --app "$ASC_APP_ID" \
        --platform IOS \
        --version "$NEW_VERSION" \
        --output json 2>"$create_err") || {
        err_msg=$(cat "$create_err")
        if echo "$err_msg" | grep -qi "already exists\|already been taken\|duplicate"; then
            echo "Version $NEW_VERSION already exists — fetching ID..."
            VERSION_JSON=$(asc versions list --app "$ASC_APP_ID" --platform IOS --output json | \
                jq -r "[.[] | select(.attributes.versionString == \"$NEW_VERSION\")] | .[0]")
        else
            echo "Error: asc versions create failed:"
            echo "$err_msg"
            rm -f "$create_err"
            exit 1
        fi
    }
    rm -f "$create_err"

    VERSION_ID=$(echo "$VERSION_JSON" | jq -r 'if type == "array" then .[0].id else .id end')
    if [[ -z "$VERSION_ID" || "$VERSION_ID" == "null" ]]; then
        echo "Error: Could not determine VERSION_ID. Check ASC credentials and app ID."
        exit 1
    fi
    echo "Version ID: $VERSION_ID"

    echo "Setting What's New (en-US)..."
    asc release-notes set \
        --version "$VERSION_ID" \
        --locale "en-US" \
        --notes "$WHATS_NEW"
fi

# ── step 3: archive ───────────────────────────────────────────────────────────
echo ""
echo "── Step 3: Archive ──────────────────────────────────────────────────────"

if $SKIP_ARCHIVE; then
    echo "Skipping archive (--skip-archive). Using: $ARCHIVE_PATH"
else
    echo "Archiving $SCHEME..."
    run xcodebuild archive \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        -allowProvisioningUpdates \
        CODE_SIGN_STYLE=Automatic \
        2>&1 | grep -E "^(Archive|error:|warning:|Build)" || true

    # Verify the archive was actually produced (pipe above may mask xcodebuild exit code)
    if ! $DRY_RUN && [[ ! -d "$ARCHIVE_PATH" ]]; then
        echo "Error: Archive not found at $ARCHIVE_PATH — xcodebuild failed."
        echo "Re-run without output filtering to see the full build log."
        exit 1
    fi
    echo "Archive complete: $ARCHIVE_PATH"
fi

# ── step 4: export + upload ───────────────────────────────────────────────────
echo ""
echo "── Step 4: Export & Upload ──────────────────────────────────────────────"

if $SKIP_UPLOAD; then
    echo "Skipping upload (--skip-upload)."
else
    echo "Exporting IPA..."
    run xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        -allowProvisioningUpdates

    IPA_PATH=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)
    if [[ -z "$IPA_PATH" ]]; then
        echo "Error: No .ipa file found in $EXPORT_PATH"
        echo "The export step may have failed. Check xcodebuild output."
        exit 1
    fi
    echo "IPA: $IPA_PATH"

    echo "Uploading to App Store Connect..."
    # asc publish handles upload + attaches build to the version
    run asc publish \
        --app "$ASC_APP_ID" \
        --ipa "$IPA_PATH" \
        --version "$NEW_VERSION"
fi

# ── done ──────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Release pipeline complete: v$NEW_VERSION (build $NEW_BUILD)"
echo ""
echo "Next steps:"
echo "  git add WhiteNoise.xcodeproj && git commit -m 'Bump version to $NEW_VERSION'"
echo "  git tag v$NEW_VERSION && git push --tags"
echo ""
echo "Screenshots (optional):"
echo "  cd screenshots && node render.mjs --all                   # iPhone"
echo "  cd screenshots && node render.mjs --all --device=ipad     # iPad"
echo "  python3 screenshots/upload_screenshots.py --device-type IPHONE_67"
echo "  python3 screenshots/upload_screenshots.py --device-type IPAD_PRO_3GEN_129"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
