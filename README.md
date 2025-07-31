# 🎵 WhiteNoise

<div align="center">
  <img src="https://img.shields.io/badge/iOS-15.0+-000000?style=for-the-badge&logo=apple&logoColor=white" alt="iOS 15.0+">
  <img src="https://img.shields.io/badge/Swift-5.0+-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 5.0+">
  <img src="https://img.shields.io/badge/SwiftUI-3.0+-0061FF?style=for-the-badge&logo=swift&logoColor=white" alt="SwiftUI">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="MIT License">
</div>

<div align="center">
  <h3>🌧️ Rain • 🔥 Fireplace • 🌊 Ocean • 🌲 Forest • ⚡ Thunder</h3>
  <p><em>Your personal ambient sound mixer for focus, relaxation, and better sleep</em></p>
</div>

---

## ✨ About WhiteNoise

WhiteNoise is a beautifully crafted iOS app that transforms your device into a powerful ambient sound machine. Whether you're trying to focus on work, meditate, or drift off to sleep, WhiteNoise provides the perfect sonic backdrop for any moment.

### 🎯 Key Features

- **🎚️ Multi-Sound Mixing** - Play multiple ambient sounds simultaneously with individual volume controls
- **⏱️ Sleep Timer** - Set a timer to automatically fade out sounds after you fall asleep
- **🌙 Background Playback** - Keep your sounds playing even when the app is in the background
- **💾 Smart Memory** - Your sound preferences are automatically saved and restored
- **🎨 Beautiful UI** - Clean, intuitive interface designed with SwiftUI
- **🔊 High-Quality Audio** - Premium sound recordings for the most authentic experience

### 🎵 Sound Library

<table>
  <tr>
    <td align="center">🌧️<br><b>Rain Sounds</b><br>Soft Rain<br>Hard Rain<br>Rain on Leaves<br>Rain on Car</td>
    <td align="center">🌲<br><b>Nature</b><br>Forest<br>Birds<br>River<br>Waterfall</td>
    <td align="center">🌊<br><b>Water</b><br>Ocean Waves<br>Sea Breeze<br>Flowing River</td>
  </tr>
  <tr>
    <td align="center">🔥<br><b>Cozy</b><br>Fireplace<br>Crackling Fire</td>
    <td align="center">⛈️<br><b>Weather</b><br>Thunder<br>Snow</td>
    <td align="center">📻<br><b>White Noise</b><br>Classic White<br>Pink Noise<br>Brown Noise</td>
  </tr>
</table>

## 📱 Screenshots

<div align="center">
  <i>Coming soon - Beautiful app screenshots showcasing the interface</i>
</div>

## 🚀 Getting Started

### Prerequisites

- iOS 15.0 or later
- Xcode 14.0 or later
- Swift 5.0 or later

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/WhiteNoise.git
   cd WhiteNoise
   ```

2. **Open in Xcode**
   ```bash
   open WhiteNoise.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### 🎯 Quick Start Guide

1. **Launch the app** - You'll see a list of available ambient sounds
2. **Tap any sound** - Toggle it on/off with a single tap
3. **Adjust volume** - Use the slider to control individual sound levels
4. **Mix sounds** - Combine multiple sounds to create your perfect atmosphere
5. **Set a timer** - Tap the timer icon to set a sleep timer with fade-out

## 🛠️ Development

### Architecture

WhiteNoise follows the **MVVM (Model-View-ViewModel)** pattern for clean separation of concerns:

```
WhiteNoise/
├── Models/          # Data models and sound definitions
├── Views/           # SwiftUI view components
├── ViewModels/      # Business logic and state management
└── Resources/       # Audio files and assets
```

### Building from Source

```bash
# Debug build
xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Debug build

# Release build
xcodebuild -project WhiteNoise.xcodeproj -scheme WhiteNoise -configuration Release build

# Run tests
xcodebuild test -project WhiteNoise.xcodeproj -scheme WhiteNoise -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Key Technologies

- **SwiftUI** - Modern declarative UI framework
- **AVFoundation** - High-performance audio playback
- **Combine** - Reactive programming for state management
- **Swift Concurrency** - Modern async/await for timer operations

## 🤝 Contributing

We love contributions! Whether it's:

- 🐛 Bug fixes
- ✨ New features
- 🎵 Additional sounds
- 📝 Documentation improvements

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for code consistency
- Write unit tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- All ambient sound recordings are royalty-free
- Built with ❤️ using SwiftUI
- Special thanks to all contributors

## 📧 Contact

Questions? Suggestions? Feel free to:

- Open an [issue](https://github.com/yourusername/WhiteNoise/issues)
- Submit a [pull request](https://github.com/yourusername/WhiteNoise/pulls)
- Reach out on [Twitter](https://twitter.com/yourusername)

---

<div align="center">
  <p>Made with 🎵 and ☕ by Ruslan Popesku</p>
  <p><b>Sweet dreams and happy focusing!</b></p>
</div>
