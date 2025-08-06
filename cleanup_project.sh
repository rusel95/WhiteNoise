#!/bin/bash

# WhiteNoise Project Cleanup Script
# This script reorganizes files to match the intended Xcode project structure

echo "🧹 Starting WhiteNoise project cleanup..."

cd /Users/Ruslan_Popesku/Desktop/WhiteNoise

# Step 1: Remove duplicates
echo "📝 Removing duplicate files..."
if [ -f "WhiteNoise/SoundViewModel.swift" ]; then
    echo "  ✓ Removing duplicate SoundViewModel.swift from root"
    rm "WhiteNoise/SoundViewModel.swift"
fi

if [ -f "WhiteNoise/WhiteNoisesViewModel.swift" ]; then
    echo "  ✓ Removing duplicate WhiteNoisesViewModel.swift from root"
    rm "WhiteNoise/WhiteNoisesViewModel.swift"
fi

# Step 2: Create directories if they don't exist
echo "📁 Creating directory structure..."
mkdir -p WhiteNoise/Models
mkdir -p WhiteNoise/Views

# Step 3: Move files to correct locations
echo "🚚 Moving files to correct directories..."

# Move Models
if [ -f "WhiteNoise/Sound.swift" ]; then
    mv "WhiteNoise/Sound.swift" "WhiteNoise/Models/"
    echo "  ✓ Moved Sound.swift to Models/"
fi

# Move Views
views=("ContentView.swift" "WhiteNoisesView.swift" "SoundView.swift" "TimerPickerView.swift" "SoundVariantPickerView.swift")
for view in "${views[@]}"; do
    if [ -f "WhiteNoise/$view" ]; then
        mv "WhiteNoise/$view" "WhiteNoise/Views/"
        echo "  ✓ Moved $view to Views/"
    fi
done

# Move SoundFactory to Services
if [ -f "WhiteNoise/SoundFactory.swift" ]; then
    mv "WhiteNoise/SoundFactory.swift" "WhiteNoise/Services/"
    echo "  ✓ Moved SoundFactory.swift to Services/"
fi

# Step 4: List final structure
echo ""
echo "📋 Final file structure:"
echo ""
echo "Models/:"
ls -la WhiteNoise/Models/ | grep ".swift"
echo ""
echo "Views/:"
ls -la WhiteNoise/Views/ | grep ".swift"
echo ""
echo "ViewModels/:"
ls -la WhiteNoise/ViewModels/ | grep ".swift"
echo ""
echo "Services/:"
ls -la WhiteNoise/Services/ | grep ".swift"
echo ""
echo "Constants/:"
ls -la WhiteNoise/Constants/ | grep ".swift"
echo ""
echo "Extensions/:"
ls -la WhiteNoise/Extensions/ | grep ".swift"
echo ""
echo "Resources/:"
ls -la WhiteNoise/Resources/ | grep ".json"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📱 Next steps:"
echo "1. Open WhiteNoise.xcodeproj in Xcode"
echo "2. Follow the instructions in XCODE_PROJECT_CLEANUP.md"
echo "3. Remove all red (missing) file references"
echo "4. Add files to proper groups as shown above"
echo "5. Clean and build the project"