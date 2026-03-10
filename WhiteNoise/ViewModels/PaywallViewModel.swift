//
//  PaywallViewModel.swift
//  WhiteNoise
//
//  Business logic for the paywall: purchase, restore, and pricing display.
//

import Foundation
import Observation
import RevenueCat

@MainActor
protocol PaywallPresenting: Observable {
    var hasFreeTrial: Bool { get }
    var priceText: String? { get }
    var monthlyPriceText: String? { get }
    var trialText: String? { get }
    var ctaText: String { get }
    var legalText: String? { get }
    var isBusy: Bool { get }
    var isReady: Bool { get }
    var errorMessage: String? { get }

    func purchase() async
    func restore() async
    func dismissPaywall()
}

@Observable @MainActor
final class PaywallViewModel: PaywallPresenting {

    // MARK: - Properties

    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    private(set) var errorMessage: String?

    private let coordinator: EntitlementsCoordinator

    // MARK: - Init

    init(coordinator: EntitlementsCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Computed Properties

    var package: Package? {
        coordinator.currentOffering?.availablePackages.first
    }

    var isBusy: Bool {
        isPurchasing || isRestoring
    }

    var isReady: Bool {
        package != nil
    }

    var hasFreeTrial: Bool {
        guard let intro = package?.storeProduct.introductoryDiscount else { return false }
        return intro.price == 0
    }

    var priceText: String? {
        guard let pkg = package else { return nil }
        let product = pkg.storeProduct
        return product.localizedPriceString + " / " + periodLabel(for: product)
    }

    var trialText: String? {
        guard let intro = package?.storeProduct.introductoryDiscount else { return nil }
        return trialLabel(for: intro)
    }

    var monthlyPriceText: String? {
        guard let pkg = package else { return nil }
        let product = pkg.storeProduct
        if let pricePerMonth = product.pricePerMonth,
           let formatted = product.priceFormatter?.string(from: pricePerMonth) {
            return formatted + String(localized: "/mo")
        }
        return nil
    }

    var trialDurationText: String? {
        guard let intro = package?.storeProduct.introductoryDiscount, intro.price == 0 else { return nil }
        return trialPeriodText(for: intro)
    }

    var ctaText: String {
        guard let pkg = package else { return String(localized: "Subscribe Now") }
        let product = pkg.storeProduct
        if hasFreeTrial {
            let price = product.localizedPriceString
            let period = periodLabel(for: product)
            return String(localized: "Start trial – then \(price)/\(period)")
        }
        return String(localized: "Subscribe Now")
    }

    var legalText: String? {
        guard let pkg = package else { return nil }
        let period = periodLabel(for: pkg.storeProduct)
        return String(localized: "Auto-renews every \(period) unless cancelled at least 24h before the period ends. Billed to your Apple ID. Manage in Settings.")
    }

    // MARK: - Actions

    func purchase() async {
        guard let pkg = package else { return }
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
        coordinator.isPaywallPresented = false
        coordinator.handlePaywallDismissed()
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

    private func trialPeriodText(for discount: StoreProductDiscount) -> String {
        let period = discount.subscriptionPeriod
        let value = period.value
        switch period.unit {
        case .day: return value == 1 ? String(localized: "1 day") : String(localized: "\(value) days")
        case .week: return value == 1 ? String(localized: "1 week") : String(localized: "\(value) weeks")
        case .month: return value == 1 ? String(localized: "1 month") : String(localized: "\(value) months")
        case .year: return value == 1 ? String(localized: "1 year") : String(localized: "\(value) years")
        @unknown default: return ""
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
