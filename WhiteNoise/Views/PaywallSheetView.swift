//
//  PaywallSheetView.swift
//  WhiteNoise
//
//  SwiftUI wrapper that displays the RevenueCat paywall inside a sheet.
//

import SwiftUI

import RevenueCat
import RevenueCatUI

/// Hosts the RevenueCat paywall inside a SwiftUI sheet and forwards events to the coordinator.
struct PaywallSheetView: View {
    @ObservedObject var coordinator: EntitlementsCoordinator

    var body: some View {
        Group {
            if let offering = coordinator.currentOffering {
                PaywallView(offering: offering)
                    .preferredColorScheme(.dark)
                    .onRequestedDismissal {
                        coordinator.isPaywallPresented = false
                        coordinator.handlePaywallDismissed()
                    }
                    .onPurchaseCompleted { customerInfo in
                        print("✅ PaywallSheetView - Purchase completed, dismissing sheet")
                        coordinator.handlePurchaseCompleted(with: customerInfo)
                        coordinator.isPaywallPresented = false
                    }
                    .onPurchaseFailure { error in
                        print("⚠️ PaywallSheetView - Purchase failed: \(error.localizedDescription)")
                    }
                    .onPurchaseCancelled {
                        print("⚠️ PaywallSheetView - Purchase cancelled by user")
                    }
                    .onRestoreCompleted { customerInfo in
                        coordinator.handleRestoreCompleted(with: customerInfo)
                    }
                    .onRestoreFailure { error in
                        print("⚠️ PaywallSheetView - Restore failed: \(error.localizedDescription)")
                    }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.85))
                    .preferredColorScheme(.dark)
            }
        }
    }
}
