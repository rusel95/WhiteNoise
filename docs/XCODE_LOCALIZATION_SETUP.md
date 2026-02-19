# Adding Localization to Xcode Project

## Summary of Changes

✅ **Modified Files:**
1. `WhiteNoise/Services/TimerService.swift` - Timer mode strings
2. `WhiteNoise/Views/TimerPickerView.swift` - UI labels  
3. `WhiteNoise/Services/SoundConfigurationLoader.swift` - Sound names & variants

✅ **Created Files:**
1. `WhiteNoise/Localizable.xcstrings` - String Catalog with 21 languages
2. `LOCALIZATION_GUIDE.md` - Implementation documentation

## Next Steps in Xcode

### 1. Add String Catalog to Xcode Project

1. Open `WhiteNoise.xcodeproj` in Xcode
2. Right-click on the `WhiteNoise` folder in Project Navigator
3. Select "Add Files to WhiteNoise..."
4. Navigate to and select `Localizable.xcstrings`
5. Make sure "Copy items if needed" is **unchecked** (file is already in correct location)
6. Click "Add"

### 2. Configure Project Localizations

1. Select the **WhiteNoise** project (blue icon) in Project Navigator
2. Go to the **Info** tab
3. Under **Localizations** section, click the **+** button
4. Add each language:
   - Arabic (ar)
   - German (de)
   - Spanish (es)
   - French (fr)
   - Hindi (hi)
   - Indonesian (id)
   - Italian (it)
   - Japanese (ja)
   - Korean (ko)
   - Dutch (nl)
   - Polish (pl)
   - Portuguese (Brazil) (pt-BR)
   - Russian (ru)
   - Thai (th)
   - Turkish (tr)
   - Ukrainian (uk) ⭐
   - Vietnamese (vi)
   - Chinese, Simplified (zh-Hans)
   - Chinese, Traditional (zh-Hant)

### 3. Verify String Catalog

1. Click on `Localizable.xcstrings` in Project Navigator
2. Xcode will show the String Catalog editor
3. Verify all strings appear with translations
4. Check for any warnings or missing translations

### 4. Test Localizations

**Method 1: Scheme Settings**
1. Product → Scheme → Edit Scheme...
2. Run → Options → App Language
3. Select a language from dropdown
4. Run the app

**Method 2: Device/Simulator Settings**
1. Open Settings app
2. General → Language & Region
3. Add/Select preferred language
4. Launch WhiteNoise app

### 5. Build and Verify

```bash
# Clean build folder
Cmd + Shift + K

# Build
Cmd + B
```

## Supported Languages (21 Total)

| Code | Language | Native Name |
|------|----------|-------------|
| en | English | English |
| ar | Arabic | العربية |
| de | German | Deutsch |
| es | Spanish | Español |
| fr | French | Français |
| hi | Hindi | हिन्दी |
| id | Indonesian | Bahasa Indonesia |
| it | Italian | Italiano |
| ja | Japanese | 日本語 |
| ko | Korean | 한국어 |
| nl | Dutch | Nederlands |
| pl | Polish | Polski |
| pt-BR | Portuguese (BR) | Português |
| ru | Russian | Русский |
| th | Thai | ไทย |
| tr | Turkish | Türkçe |
| **uk** | **Ukrainian** | **Українська** ⭐ |
| vi | Vietnamese | Tiếng Việt |
| zh-Hans | Chinese (Simplified) | 简体中文 |
| zh-Hant | Chinese (Traditional) | 繁體中文 |

## What Gets Localized

### Timer Modes
- Off / Вимк / オフ / 关闭 / etc.
- All time durations (1 minute to 8 hours)

### UI Elements
- "Sleep Timer" → "Таймер сну" (Ukrainian), "スリープタイマー" (Japanese), etc.
- "Done" button → "Готово" (Ukrainian), "完了" (Japanese), etc.

### Sound Names
All 9 sound categories:
- rain / дощ / 雨
- bonfire / вогнище / 焚き火  
- waterfall / водоспад / 滝
- forest / ліс / 森
- white noise / білий шум / ホワイトノイズ
- brown noise / коричневий шум / ブラウンノイズ
- ocean / океан / 海洋
- thunderstorm / гроза / 雷暴
- river / річка / 河流

### Sound Variants
All variant names from SoundConfiguration.json will be localized

## Troubleshooting

**Issue**: Strings not appearing in String Catalog editor
- **Fix**: Make sure `Localizable.xcstrings` is added to the target

**Issue**: Translations not showing in app
- **Fix**: Clean build folder (Cmd+Shift+K) and rebuild

**Issue**: Missing translations
- **Fix**: Open String Catalog, click on string, add missing language

## RTL (Right-to-Left) Support

Arabic automatically uses RTL layout. No additional code needed - SwiftUI handles this natively.
