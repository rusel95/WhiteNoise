# Asset Symbols and System Images Guide

This guide shows how to use type-safe asset symbols and SF Symbols throughout your WhiteNoise project.

## Part 1: Asset Catalog Symbols (Images & Colors)

### Enabled Setting
✅ `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES`

Xcode automatically generates type-safe symbols for all assets in your asset catalog.

### Available Color Symbols
```swift
import SwiftUI

// All generated automatically from Assets.xcassets
Color.accent
Color.black30
Color.black90
Color.launchScreenBackground
Color.primaryGradientStart
Color.primaryGradientEnd
Color.secondaryGradientStart
Color.secondaryGradientEnd
```

### Available Image Symbols
```swift
Image.waterfall
Image.sea
Image._1024
Image._1024Logo
UIImage.launchScreenIcon
```

### Usage Example
```swift
// Before (string-based)
let gradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.2, green: 0.5, blue: 0.6),
        Color(red: 0.1, green: 0.4, blue: 0.5)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// After (type-safe with asset symbols)
let gradient = LinearGradient(
    gradient: Gradient(colors: [
        Color.primaryGradientStart,
        Color.primaryGradientEnd
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

---

## Part 2: System Images (SF Symbols) - Type-Safe Approach

### The New SystemImage Enum
A custom enum in `Models/SystemImage.swift` provides type-safe access to SF Symbols:

```swift
enum SystemImage: String, CaseIterable {
    case cloudRain = "cloud.rain"
    case flame
    case tree
    case waveformPath = "waveform.path"
    case waterWaves = "water.waves"
    case cloudBolt = "cloud.bolt"
    case bird
    case fireplace
    case pauseFill = "pause.fill"
    case play
    case playFill = "play.fill"
    case pause
    case timer
    case chevronDown = "chevron.down"
    // ... and more
}
```

### SwiftUI Extension
```swift
extension Image {
    init(system: SystemImage) {
        self.init(systemName: system.systemName)
    }
}
```

### Usage Examples

#### Before (String-based)
```swift
// Easy to make typos!
Image(systemName: "cloud.rain")
Image(systemName: "clod.rain")  // ❌ Typo! Won't fail until runtime
```

#### After (Type-safe)
```swift
// Compiler checks this!
Image(system: .cloudRain)       // ✅ IDE autocomplete, compile-time checking
```

### Practical Usage in Views

#### SoundView.swift Example
```swift
switch viewModel.sound.icon {
case .system(let systemName):
    // Option 1: Keep existing string-based for SoundConfiguration.json compatibility
    Image(systemName: systemName)
        .font(.system(size: AppConstants.UI.soundNameFontSize))
        .foregroundColor(.white)

case .custom(let name):
    Image(name)
        .resizable()
        .frame(width: AppConstants.UI.soundCardIconSize,
               height: AppConstants.UI.soundCardIconSize)
}
```

#### Using SystemImage Directly
```swift
// For hardcoded icons in your views
VStack {
    Image(system: .cloudRain)
        .font(.title)
        .foregroundColor(.white)

    Text("Rain")
}
```

#### Control Buttons
```swift
// Play button
Button(action: {}) {
    Image(system: .play)
        .font(.system(size: 24))
}

// Pause button
Button(action: {}) {
    Image(system: .pause)
        .font(.system(size: 24))
}

// Timer button
Button(action: {}) {
    Image(system: .timer)
        .font(.system(size: 20))
}
```

---

## Part 3: Alternative Approaches for iOS 17.0+

If you upgrade to iOS 17.0+ as minimum deployment target, you can use **Symbol Sets** directly in your asset catalog:

### Creating a Symbol Set
1. Open `Assets.xcassets` in Xcode
2. Click `+` → "Symbol Set"
3. Name it (e.g., "cloud-rain")
4. Xcode generates: `Image(.cloudRain)` or `Image(resource: .cloudRain)`

### Advantages over SystemImage enum
- Managed directly in asset catalog UI
- Can configure weight, scale, and appearance in Xcode
- Single source of truth in Xcode

### Disadvantages
- iOS 17.0+ only
- Can't use if supporting iOS 16.0

---

## Migration Path

### Phase 1: Current State ✅
- Asset symbols for colors and images fully working
- System images still use strings from SoundConfiguration.json
- SystemImage enum available for new code

### Phase 2: Optional Gradual Migration
- Update `SoundConfiguration.json` icon references to use type-safe SystemImage
- Modify `Icon` enum to support `systemSymbol(SystemImage)`
- Update `SoundView.swift` rendering logic

Example:
```swift
// In Sound.swift
enum Icon: Codable {
    case system(String)              // Old: "cloud.rain"
    case systemSymbol(SystemImage)   // New: .cloudRain
    case custom(String)              // Custom images
}

// In SoundView.swift
switch viewModel.sound.icon {
case .system(let systemName):
    Image(systemName: systemName)

case .systemSymbol(let systemImage):
    Image(system: systemImage)        // Type-safe!

case .custom(let name):
    Image(name)
}
```

### Phase 3: Full Type-Safety (Optional Future)
- Replace all `Image(systemName: "...")` with `Image(system: .xxx)`
- Update SoundConfiguration.json with type-safe references
- Add new symbols to SystemImage enum as needed

---

## Best Practices

✅ **DO:**
- Use `Color.primaryGradientStart` instead of `Color(red: 0.2, green: 0.5, blue: 0.6)`
- Use `Image.waterfall` instead of `Image("waterfall")`
- Use `Image(system: .cloudRain)` for new code
- Use `UIImage.launchScreenIcon` instead of `UIImage(named: "LaunchScreenIcon")`
- Add new SF Symbols to the `SystemImage` enum as you use them

❌ **DON'T:**
- Hardcode RGB values - add them to the asset catalog
- Use string literals for images - use asset symbols
- Use `Image(systemName: "typo.name")` - use `Image(system: .symbolName)`

---

## File Locations

- **Asset Symbols Generated**: `GeneratedAssetSymbols.swift` (auto-generated during build)
- **Color Assets**: `WhiteNoise/Assets.xcassets/Colors/`
- **Image Assets**: `WhiteNoise/Assets.xcassets/*.imageset/`
- **System Image Wrapper**: `WhiteNoise/Models/SystemImage.swift`
- **Usage Examples**: This document

---

## Quick Reference

| Use Case | Before | After |
|----------|--------|-------|
| Gradient color | `Color(red: 0.2, green: 0.5, blue: 0.6)` | `Color.primaryGradientStart` |
| Named color | `Color("black90")` | `Color.black90` |
| Custom image | `Image("waterfall")` | `Image.waterfall` |
| System icon (new) | `Image(systemName: "cloud.rain")` | `Image(system: .cloudRain)` |
| Launch icon | `UIImage(named: "LaunchScreenIcon")` | `UIImage.launchScreenIcon` |

