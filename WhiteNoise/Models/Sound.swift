//
//  Sound.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 30.05.2023.
//

import Foundation

struct Sound: Codable, Identifiable {

    struct SoundVariant: Codable, Identifiable, Hashable {
        let id: UUID
        let name: String
        let filename: String

        init(
            id: UUID = UUID(),
            name: String,
            filename: String
        ) {
            self.id = id
            self.name = name
            self.filename = filename
        }
    }

    enum Icon: Codable {
        case system(String)
        case custom(String)
    }

    enum SoundError: Error, LocalizedError {
        case noVariantsProvided
        case invalidVariantSelection

        var errorDescription: String? {
            switch self {
            case .noVariantsProvided:
                return "Sound must have at least one variant"
            case .invalidVariantSelection:
                return "Selected variant is not in variants list"
            }
        }
    }

    var id: String { name }

    let name: String
    let icon: Icon
    var volume: Float
    var selectedSoundVariant: SoundVariant
    let soundVariants: [SoundVariant]

    init(
        name: String,
        icon: Icon,
        volume: Float = 0.0,
        selectedSoundVariant: SoundVariant?,
        soundVariants: [SoundVariant]
    ) throws {
        guard !soundVariants.isEmpty else {
            TelemetryService.captureNonFatal(
                message: "Sound.init failed: no variants provided",
                level: .error,
                extra: ["soundName": name]
            )
            throw SoundError.noVariantsProvided
        }

        self.name = name
        self.icon = icon
        self.volume = volume
        self.soundVariants = soundVariants

        if let selected = selectedSoundVariant {
            guard soundVariants.contains(where: { $0.id == selected.id }) else {
                TelemetryService.captureNonFatal(
                    message: "Sound.init failed: invalid variant selection",
                    level: .error,
                    extra: ["soundName": name, "selectedVariant": selected.name]
                )
                throw SoundError.invalidVariantSelection
            }
            self.selectedSoundVariant = selected
        } else {
            self.selectedSoundVariant = soundVariants.first!
        }
    }
}
