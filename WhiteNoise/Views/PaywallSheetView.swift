//
//  PaywallSheetView.swift
//  WhiteNoise
//
//  SwiftUI wrapper that displays the Adapty paywall inside a sheet.
//

import SwiftUI

#if canImport(Adapty)
import Adapty
#endif
#if canImport(AdaptyUI)
import AdaptyUI
#endif

struct PaywallSheetView: View {
    @ObservedObject var coordinator: EntitlementsCoordinator

    var body: some View {
        Group {
            #if canImport(AdaptyUI)
            if let configuration = coordinator.paywallConfiguration {
                AdaptyPaywallView(
                    paywallConfiguration: configuration,
                    didDisappear: {
                        coordinator.handlePaywallDismissed()
                    },
                    didFinishPurchase: { _, _ in
                        coordinator.handlePurchaseCompleted()
                    },
                    didFailPurchase: { _, error in
                        print("⚠️ PaywallSheetView - Purchase failed: \(error.localizedDescription)")
                    },
                    didFinishRestore: { profile in
                        coordinator.handleRestoreCompleted(with: profile)
                    },
                    didFailRestore: { error in
                        print("⚠️ PaywallSheetView - Restore failed: \(error.localizedDescription)")
                    },
                    didFailRendering: { error in
                        print("❌ PaywallSheetView - Rendering failed: \(error.localizedDescription)")
                        coordinator.handlePaywallRenderingFailure()
                    }
                )
                .preferredColorScheme(.dark)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.85))
                    .preferredColorScheme(.dark)
            }
            #else
            Text("Paywall requires AdaptyUI package.")
                .padding()
            #endif
        }
    }
}

