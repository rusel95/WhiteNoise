#!/bin/bash

# Upload Debug Symbols to Sentry
# This script is executed as part of the Xcode build process

# Only upload debug symbols for Release builds
if [ "$CONFIGURATION" = "Release" ]; then
    echo "Uploading debug symbols to Sentry..."
    
    # Check if sentry-cli is available
    if command -v sentry-cli >/dev/null 2>&1; then
        # Upload dSYMs to Sentry
        sentry-cli upload-dif --include-sources "$DWARF_DSYM_FOLDER_PATH"
        echo "Debug symbols uploaded successfully to Sentry"
    else
        echo "Warning: sentry-cli not found. Please install it using 'brew install sentry-cli'"
    fi
else
    echo "Skipping Sentry upload for $CONFIGURATION build"
fi