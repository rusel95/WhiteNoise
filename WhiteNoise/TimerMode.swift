//
//  TimerMode.swift
//  WhiteNoise
//
//  Created by Ruslan Popesku on 26.07.2024.
//

enum TimerMode: CaseIterable, Identifiable {

    var id: Self { self }

    case off, oneMinute, twoMinutes, threeMinutes, fiveMinutes, tenMinutes, fifteenMinutes, thirtyMinutes, sixtyMinutes

    var minutes: Int {
        switch self {
        case .off:
            return 0
        case .oneMinute:
            return 1
        case .twoMinutes:
            return 2
        case .threeMinutes:
            return 3
        case .fiveMinutes:
            return 5
        case .tenMinutes:
            return 10
        case .fifteenMinutes:
            return 15
        case .thirtyMinutes:
            return 30
        case .sixtyMinutes:
            return 60
        }
    }

    var description: String {
        switch self {
        case .off:
            return "off"
        case .oneMinute:
            return "in 1 minute"
        case .twoMinutes:
            return "in 2 minutes"
        case .threeMinutes:
            return "in 3 minutes"
        case .fiveMinutes:
            return "in 5 minutes"
        case .tenMinutes:
            return "in 10 minutes"
        case .fifteenMinutes:
            return "in 15 minutes"
        case .thirtyMinutes:
            return "in 30 minutes"
        case .sixtyMinutes:
            return "in 60 minutes"
        }
    }
}
