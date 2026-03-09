//
//  PaywallViewModel.swift
//  WhiteNoise
//
//  Business logic for the paywall: purchase, restore, and pricing display.
//

import Foundation
import RevenueCat

@Observable @MainActor
final class PaywallViewModel {

    // MARK: - Properties

    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    private(set) var errorMessage: String?

    private let coordinator: EntitlementsCoordinator?
    private let mockPriceText: String?
    private let mockTrialText: String?
    private let mockLegalText: String?
    private let mockHasFreeTrial: Bool

    // MARK: - Init

    init(coordinator: EntitlementsCoordinator) {
        self.coordinator = coordinator
        self.mockPriceText = nil
        self.mockTrialText = nil
        self.mockLegalText = nil
        self.mockHasFreeTrial = false
    }

    #if DEBUG
    init(
        priceText: String = "$4.99 / month",
        trialText: String? = "Includes 3 day free trial",
        legalText: String = "Auto-renews every month unless cancelled at least 24h before the period ends. Billed to your Apple ID. Manage in Settings.",
        hasFreeTrial: Bool = true
    ) {
        self.coordinator = nil
        self.mockPriceText = priceText
        self.mockTrialText = trialText
        self.mockLegalText = legalText
        self.mockHasFreeTrial = hasFreeTrial
    }
    #endif

    // MARK: - Computed Properties

    var package: Package? {
        coordinator?.currentOffering?.availablePackages.first
    }

    var isBusy: Bool {
        isPurchasing || isRestoring
    }

    var isReady: Bool {
        mockPriceText != nil || package != nil
    }

    var hasFreeTrial: Bool {
        if mockPriceText != nil { return mockHasFreeTrial }
        guard let intro = package?.storeProduct.introductoryDiscount else { return false }
        return intro.price == 0
    }

    var priceText: String? {
        if let mock = mockPriceText { return mock }
        guard let pkg = package else { return nil }
        let product = pkg.storeProduct
        return product.localizedPriceString + " / " + periodLabel(for: product)
    }

    var trialText: String? {
        if mockPriceText != nil { return mockTrialText }
        guard let intro = package?.storeProduct.introductoryDiscount else { return nil }
        return trialLabel(for: intro)
    }

    var legalText: String? {
        if let mock = mockLegalText { return mock }
        guard let pkg = package else { return nil }
        let period = periodLabel(for: pkg.storeProduct)
        return String(localized: "Auto-renews every \(period) unless cancelled at least 24h before the period ends. Billed to your Apple ID. Manage in Settings.")
    }

    // MARK: - Actions

    func purchase() async {
        guard let coordinator, let pkg = package else { return }
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await Purchases.shared.purchase(package: pkg)
            if !result.userCancelled {
                coordinator.handlePurchaseCompleted(with: result.customerInfo)
                coordinator.isPaywallPresented = false
            } else {
                AnalyticsService.capture(.purchaseCancelled)
                LoggingService.log("PaywallViewModel - Purchase cancelled by user")
            }
        } catch is CancellationError {
            // Silent — user navigated away
        } catch {
            errorMessage = String(localized: "Something went wrong. Please try again.")
            AnalyticsService.capture(.purchaseFailed(error: error.localizedDescription))
            TelemetryService.captureNonFatal(
                error: error,
                message: "PaywallViewModel - Purchase failed"
            )
            LoggingService.log("PaywallViewModel - Purchase failed: \(error.localizedDescription)")
        }

        isPurchasing = false
    }

    func restore() async {
        guard let coordinator else { return }
        isRestoring = true
        errorMessage = nil

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            coordinator.handleRestoreCompleted(with: customerInfo)
        } catch is CancellationError {
            // Silent
        } catch {
            errorMessage = String(localized: "Restore failed. Please try again.")
            AnalyticsService.capture(.restoreFailed(error: error.localizedDescription))
            TelemetryService.captureNonFatal(
                error: error,
                message: "PaywallViewModel - Restore failed"
            )
            LoggingService.log("PaywallViewModel - Restore failed: \(error.localizedDescription)")
        }

        isRestoring = false
    }

    func dismissPaywall() {
        coordinator?.isPaywallPresented = false
        coordinator?.handlePaywallDismissed()
    }

    // MARK: - Private Helpers

    private func periodLabel(for product: StoreProduct) -> String {
        guard let period = product.subscriptionPeriod else { return "" }
        switch period.unit {
        case .day: return period.value == 7 ? String(localized: "week") : String(localized: "\(period.value) days")
        case .week: return String(localized: "week")
        case .month: return period.value == 1 ? String(localized: "month") : String(localized: "\(period.value) months")
        case .year: return String(localized: "year")
        @unknown default:
            LoggingService.log("PaywallViewModel.periodLabel - Unknown subscription period unit")
            return ""
        }
    }

    private func trialLabel(for discount: StoreProductDiscount) -> String {
        let period = discount.subscriptionPeriod
        let value = period.value
        let unitName: String
        switch period.unit {
        case .day: unitName = String(localized: "day")
        case .week: unitName = String(localized: "week")
        case .month: unitName = String(localized: "month")
        case .year: unitName = String(localized: "year")
        @unknown default:
            LoggingService.log("PaywallViewModel.trialLabel - Unknown subscription period unit")
            return ""
        }
        return String(localized: "Includes \(value) \(unitName) free trial")
    }
}
