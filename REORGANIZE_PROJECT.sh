#!/bin/bash

# Script to reorganize WhiteNoise project structure
# Run this from the WhiteNoise project root directory

echo "🔧 Starting WhiteNoise project reorganization..."

# Create proper directory structure
echo "📁 Creating directory structure..."
mkdir -p WhiteNoise/Models
mkdir -p WhiteNoise/Views
mkdir -p WhiteNoise/ViewModels
mkdir -p WhiteNoise/Services
mkdir -p WhiteNoise/Constants
mkdir -p WhiteNoise/Extensions
mkdir -p WhiteNoise/Resources

# Move files to proper locations
echo "📦 Moving files to correct directories..."

# Move Models
if [ -f "WhiteNoise/Sound.swift" ]; then
    mv WhiteNoise/Sound.swift WhiteNoise/Models/
    echo "✓ Moved Sound.swift to Models"
fi

# Move Views
for file in ContentView.swift WhiteNoisesView.swift SoundView.swift TimerPickerView.swift SoundVariantPickerView.swift; do
    if [ -f "WhiteNoise/$file" ]; then
        mv "WhiteNoise/$file" "WhiteNoise/Views/"
        echo "✓ Moved $file to Views"
    fi
done

# ViewModels are already in correct location
echo "✓ ViewModels already in correct location"

# Move SoundFactory to Services
if [ -f "WhiteNoise/SoundFactory.swift" ]; then
    mv WhiteNoise/SoundFactory.swift WhiteNoise/Services/
    echo "✓ Moved SoundFactory.swift to Services"
fi

# List all Swift files that need to be added to project
echo ""
echo "📋 Files that need to be added to Xcode project:"
echo ""
echo "Models Group:"
find WhiteNoise/Models -name "*.swift" -type f | sort

echo ""
echo "Views Group:"
find WhiteNoise/Views -name "*.swift" -type f | sort

echo ""
echo "ViewModels Group:"
find WhiteNoise/ViewModels -name "*.swift" -type f | sort

echo ""
echo "Services Group:"
find WhiteNoise/Services -name "*.swift" -type f | sort

echo ""
echo "Constants Group:"
find WhiteNoise/Constants -name "*.swift" -type f | sort

echo ""
echo "Extensions Group:"
find WhiteNoise/Extensions -name "*.swift" -type f | sort

echo ""
echo "Resources:"
find WhiteNoise/Resources -name "*.json" -type f | sort

echo ""
echo "Root Level Files:"
echo "- WhiteNoise/WhiteNoiseApp.swift"
echo "- WhiteNoise/WhiteNoise.entitlements"
echo "- WhiteNoise/Info.plist"

echo ""
echo "❗ Sentry-related files (if you want to use them):"
echo "- WhiteNoise/ErrorTracking.swift"
echo "- WhiteNoise/SentryConfiguration.swift"
echo "- WhiteNoise/SentrySetup.swift"

echo ""
echo "✅ File reorganization complete!"
echo ""
echo "📱 Next Steps:"
echo "1. Open WhiteNoise.xcodeproj in Xcode"
echo "2. Delete all red (missing) file references"
echo "3. Right-click on WhiteNoise folder and 'Add Files to WhiteNoise...'"
echo "4. Add each group folder (Models, Views, ViewModels, Services, Constants, Extensions)"
echo "5. Make sure 'Create groups' is selected"
echo "6. Add Resources/SoundConfiguration.json to 'Copy Bundle Resources' build phase"
echo "7. Clean build folder (Cmd+Shift+K)"
echo "8. Build the project (Cmd+B)"