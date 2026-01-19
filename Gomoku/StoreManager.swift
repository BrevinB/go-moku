//
//  StoreManager.swift
//  Gomoku
//
//  Created by Claude on 12/13/25.
//

import Foundation
import RevenueCat

// MARK: - Coin Pack Definitions

enum CoinPack: String, CaseIterable {
    case small = "com.gomoku.coins.100"    // $0.99 = 1000 coins (baseline)
    case medium = "com.gomoku.coins.400"   // $2.99 = 3000 coins (+50% value)
    case large = "com.gomoku.coins.1000"   // $4.99 = 6000 coins (best value)

    var coinAmount: Int {
        switch self {
        case .small: return 1000
        case .medium: return 3000
        case .large: return 6000
        }
    }

    var displayName: String {
        switch self {
        case .small: return "1,000 Coins"
        case .medium: return "3,000 Coins"
        case .large: return "6,000 Coins"
        }
    }

    var displayPrice: String {
        switch self {
        case .small: return "$0.99"
        case .medium: return "$2.99"
        case .large: return "$4.99"
        }
    }

    var valueText: String? {
        switch self {
        case .small: return nil
        case .medium: return "+50% Value"
        case .large: return "BEST VALUE"
        }
    }
}

// MARK: - Store Manager

class StoreManager {
    static let shared = StoreManager()

    // Replace with your actual RevenueCat API key
    private let apiKey = "appl_hGcPqjFZpwJuGkIDBoKhvmYmJUS"

    private(set) var products: [String: StoreProduct] = [:]
    private(set) var isConfigured = false

    private init() {}

    // MARK: - Configuration

    /// Configure RevenueCat - call this in AppDelegate.didFinishLaunching
    func configure() {
        guard !isConfigured else { return }

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        isConfigured = true

        // Load products
        Task {
            await loadProducts()
        }
    }

    // MARK: - Products

    /// Load available products from RevenueCat
    @MainActor
    func loadProducts() async {
        do {
            let offerings = try await Purchases.shared.offerings()

            if let current = offerings.current {
                for package in current.availablePackages {
                    products[package.storeProduct.productIdentifier] = package.storeProduct
                }
            }

            // Also try to fetch individual products
            let productIds = CoinPack.allCases.map { $0.rawValue }
            let fetchedProducts = try await Purchases.shared.products(productIds)
            for product in fetchedProducts {
                products[product.productIdentifier] = product
            }

            print("StoreManager: Loaded \(products.count) products")
        } catch {
            print("StoreManager: Failed to load products: \(error.localizedDescription)")
        }
    }

    /// Get a product by pack type
    func getProduct(for pack: CoinPack) -> StoreProduct? {
        return products[pack.rawValue]
    }

    /// Get localized price for a pack (falls back to display price if product not loaded)
    func getLocalizedPrice(for pack: CoinPack) -> String {
        if let product = products[pack.rawValue] {
            return product.localizedPriceString
        }
        return pack.displayPrice
    }

    // MARK: - Purchases

    /// Purchase a coin pack
    /// - Parameter pack: The coin pack to purchase
    /// - Returns: True if purchase was successful
    @MainActor
    func purchase(_ pack: CoinPack) async throws -> Bool {
        guard let product = products[pack.rawValue] else {
            // Try to fetch the product if not cached
            let fetchedProducts = try await Purchases.shared.products([pack.rawValue])
            guard let product = fetchedProducts.first else {
                throw StoreError.productNotFound
            }
            products[pack.rawValue] = product
            return try await performPurchase(product, coinAmount: pack.coinAmount)
        }

        return try await performPurchase(product, coinAmount: pack.coinAmount)
    }

    private func performPurchase(_ product: StoreProduct, coinAmount: Int) async throws -> Bool {
        let result = try await Purchases.shared.purchase(product: product)

        if !result.userCancelled {
            // Award coins
            CoinManager.shared.addCoins(coinAmount)
            print("StoreManager: Purchased \(coinAmount) coins")
            return true
        }

        return false
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    /// Note: Consumables (coins) cannot be restored, but this is included for App Store compliance
    @MainActor
    func restorePurchases() async throws {
        let customerInfo = try await Purchases.shared.restorePurchases()
        print("StoreManager: Restored purchases. Active entitlements: \(customerInfo.entitlements.active.keys)")
        // Note: Consumables don't restore, this is mainly for non-consumable themes if you add them later
    }
}

// MARK: - Store Errors

enum StoreError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found. Please try again later."
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .notConfigured:
            return "Store not configured. Please restart the app."
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let coinsUpdated = Notification.Name("coinsUpdated")
}
