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

/// Hosts the Adapty paywall inside a SwiftUI sheet and forwards events to the coordinator.
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
                    didFinishPurchase: { _, result in
                        // When we provide a custom handler, Adapty's default auto-dismiss is overridden.
                        // Manually dismiss the sheet and refresh entitlements on successful purchase.
                        if !result.isPurchaseCancelled {
                            print("✅ PaywallSheetView - Purchase completed, dismissing sheet")
                            coordinator.handlePurchaseCompleted(profile: result.profile)
                            coordinator.isPaywallPresented = false
                        }
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
