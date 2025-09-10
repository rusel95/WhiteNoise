#!/usr/bin/env bash
set -euo pipefail

# Simple test runner for the WhiteNoise project
# Usage:
#   bash scripts/test.sh
# Optional env vars:
#   SCHEME=WhiteNoise
#   PROJECT=WhiteNoise.xcodeproj
#   DESTINATION="platform=iOS Simulator,name=iPhone 15"

SCHEME=${SCHEME:-WhiteNoise}
PROJECT=${PROJECT:-WhiteNoise.xcodeproj}
DESTINATION=${DESTINATION:-"platform=iOS Simulator,name=iPhone 15"}

echo "Running tests for scheme: $SCHEME"
set -x
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION"
