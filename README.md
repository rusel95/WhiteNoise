# 🎵 White Sound

<div align="center">
  <img src="https://img.shields.io/badge/iOS-15.0+-000000?style=flat-square&logo=apple&logoColor=white" alt="iOS 15.0+">
  <img src="https://img.shields.io/badge/Swift-5.0+-FA7343?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.0+">
  <img src="https://img.shields.io/badge/SwiftUI-blue?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/badge/Open%20Source-❤️-red?style=flat-square" alt="Open Source">
  <br>
  <img src="https://visitor-badge.laobi.icu/badge?page_id=ruslanpopesku.whitenoise" alt="Visitors">
</div>

## About

![ScreenRecording_07-30-202512-07-55_1-ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/114063c8-1fe3-478c-b676-247698841ed7)

White Sound is an iOS ambient sound mixer for focus, relaxation, and better sleep. Mix multiple sounds, set sleep timers, and enjoy background playback.

### Features

- 🎚️ **Multi-Sound Mixing** - Layer multiple ambient sounds with individual volume controls
- ⏱️ **Sleep Timer** - Auto fade-out after you fall asleep
- 🌙 **Background Playback** - Continues playing when app is minimized
- 💾 **Smart Memory** - Saves your sound preferences

### Sounds

🌧️ **Rain** • 🔥 **Fireplace** • 🌊 **Ocean** • 🌲 **Forest** • ⛈️ **Thunder** • 📻 **White Noise**

## Installation

```bash
git clone https://github.com/yourusername/WhiteNoise.git
cd WhiteNoise
open WhiteNoise.xcodeproj
```

Press `Cmd + R` to build and run.

## Usage

1. Tap sounds to toggle on/off
2. Adjust individual volumes with sliders
3. Mix multiple sounds together
4. Set sleep timer from timer menu

## Development

Built with SwiftUI + AVFoundation using MVVM architecture.

### Configuration

- Copy `WhiteNoise/Configuration/Local.example.xcconfig` to `WhiteNoise/Configuration/Local.xcconfig`.
- Add your private `SENTRY_DSN` (and optional RevenueCat overrides) to the copied file.
- Alternatively, pass `SENTRY_DSN` via scheme/run arguments or `SENTRY_DSN=... xcodebuild …` when running from the command line.

## Tests

- Run all tests from CLI:
  - `xcodebuild test -project WhiteNoise.xcodeproj -scheme WhiteNoise -destination 'platform=iOS Simulator,name=iPhone 15'`
- Or use the helper script:
  - `bash scripts/test.sh`
- In Xcode: open the project and press `Cmd + U`.

Notes:
- Includes unit tests for timer lifecycle and fade operations:
  - `WhiteNoiseUnitTests/TimerServiceTests.swift`
  - `WhiteNoiseUnitTests/FadeOperationTests.swift`
- The scheme already includes the `WhiteNoiseUnitTests` target.

## Contributing

PRs welcome! Please follow Swift API Design Guidelines.

---

<div align="center">
  <p>Made with 🎵 by Ruslan Popesku</p>
  <p>MIT Licensed</p>
</div>
