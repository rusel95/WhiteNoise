# Sound Configuration & Asset Guide

The ambient catalogue is data-driven. This guide explains how `SoundConfiguration.json` maps to bundled audio files and what to watch for when editing the catalogue.

## File Location & Build Settings
- Source: `WhiteNoise/Sounds/SoundConfiguration.json`
- Ensure the JSON file is included in the Xcode project’s **Copy Bundle Resources** phase so `Bundle.main.url(forResource:withExtension:)` can find it at runtime.
- Keep filenames *without* extensions inside the JSON. `AVAudioPlayerFactory` appends supported extensions (`m4a`, `wav`, `aac`, `mp3`, `aiff`, `caf`) until it finds a match.

## Schema Overview
```json
{
  "sounds": [
    {
      "name": "rain",
      "icon": { "type": "system", "value": "cloud.rain" },
      "variants": [
        { "name": "soft drops", "filename": "584945__richwise__rain-loop-1" }
      ]
    }
  ]
}
```
- `name`: Unique identifier for a sound family; also used as the persistence key suffix (`sound_<name>`).
- `icon`: Either `system` (SF Symbol name) or `custom` (asset catalog image name).
- `variants`: At least one per sound. Each variant maps a display `name` to a `filename` (again, extension-less).

## Default Volume Policy
`SoundConfigurationLoader` applies special-case defaults before persistence overrides kick in:
- Rain → 70%
- Thunder → 30%
- Birds → 20%
- Every other sound defaults to `AppConstants.Audio.defaultVolume` (currently 0).

If you add new sounds that should start louder than 0, update the switch inside `SoundConfigurationLoader` accordingly.

## Asset Organisation
- Audio files live under `WhiteNoise/Sounds/<category>/...`. The directory name does **not** need to match the variant name, but organised folders make maintenance easier.
- Keep filenames consistent between disk and JSON. Typos (`"sprint"` vs `"spring"`, trailing spaces) will cause runtime lookup failures.
- Avoid trailing commas or comments in JSON—Swift’s `JSONDecoder` expects strict JSON. Clean the file before committing to prevent runtime decoding errors.

## Adding a New Sound
1. Drop the new audio assets into `WhiteNoise/Sounds/<category>/`.
2. Update `SoundConfiguration.json` with a new entry and variant list.
3. If you introduce custom icons, add an image set to `WhiteNoise/Assets.xcassets` with the same name.
4. Validate by running the app and confirming the sound appears, loads, and persists volume changes.
5. Update documentation (`MEMORY_BANK.md`, this file, or `ARCHITECTURE.md`) if you change conventions.

## Troubleshooting
- **Sound does not play**: check that the filename in JSON matches the bundled file (no extension, no stray spaces), and ensure the asset is part of the target membership in Xcode.
- **Configuration fails to decode**: run the JSON through a formatter/linter or `jq` to surface syntax errors.
- **Wrong default volume**: confirm you are not overriding the loader logic in `SoundFactory`. Persisted values (UserDefaults) win after the first play.

Document additional quirks as they surface so future edits remain painless.
