//
//  GiftManager.swift
//  Gomoku
//
//  Generates and redeems coin-gift codes that players can share via any messaging app.
//
//  Code format: GMK-AAAA-BBBB-CCCC-DDDD (20 hex chars + dashes)
//    AAAA      = amount  (uint16, big-endian)   — 0..65535 coins
//    BBBBCCCC  = nonce   (8 hex chars, random)  — prevents double-redeem
//    DDDD      = HMAC-SHA256(secret, amount||nonce) truncated to 4 hex chars (16 bits)
//
//  HMAC is a tamper signal only — anyone with the app binary can forge codes. That's
//  acceptable for a casual gift mechanic; the worst case is a small amount of bogus
//  coins. We do prevent replay via the redeemed-nonce store.
//

import Foundation
import CryptoKit

class GiftManager {
    static let shared = GiftManager()

    private let redeemedNoncesKey = "redeemedGiftNonces"
    // Not a real secret — see comment above. Just discriminates from random text input.
    private let secret = "gomoku-gift-v1-7a3f9c"
    private let prefix = "GMK"
    private let maxGiftAmount = 5000

    private init() {}

    // MARK: - Generation

    enum GiftError: Error, LocalizedError {
        case amountTooLarge
        case amountTooSmall
        case insufficientCoins
        case invalidFormat
        case invalidSignature
        case alreadyRedeemed
        case selfRedeemBlocked

        var errorDescription: String? {
            switch self {
            case .amountTooLarge: return "Gifts are capped at \(GiftManager.shared.maxGiftAmount) coins."
            case .amountTooSmall: return "Gift at least 10 coins."
            case .insufficientCoins: return "Not enough coins to send this gift."
            case .invalidFormat: return "That code doesn't look right."
            case .invalidSignature: return "This gift code is invalid or corrupted."
            case .alreadyRedeemed: return "This gift code has already been redeemed."
            case .selfRedeemBlocked: return "You can't redeem your own gift."
            }
        }
    }

    /// Spend `amount` coins from the local balance and return a shareable gift code.
    func createGift(amount: Int) throws -> String {
        guard amount >= 10 else { throw GiftError.amountTooSmall }
        guard amount <= maxGiftAmount else { throw GiftError.amountTooLarge }
        guard CoinManager.shared.spendCoins(amount) else { throw GiftError.insufficientCoins }

        let nonce = UInt32.random(in: 0...UInt32.max)
        let code = encode(amount: UInt16(amount), nonce: nonce)
        // Track our own outgoing nonces so we can refuse to self-redeem.
        recordOwnGiftNonce(nonce)
        return code
    }

    /// Validate and redeem a code. Adds coins on success.
    @discardableResult
    func redeem(code: String) throws -> Int {
        let normalized = code.uppercased().replacingOccurrences(of: " ", with: "")
        let parts = normalized.split(separator: "-").map(String.init)
        guard parts.count == 5, parts[0] == prefix else { throw GiftError.invalidFormat }
        let amountHex = parts[1]
        let nonceHex = parts[2] + parts[3]
        let sigHex = parts[4]

        guard amountHex.count == 4, nonceHex.count == 8, sigHex.count == 4 else {
            throw GiftError.invalidFormat
        }
        guard let amount = UInt16(amountHex, radix: 16),
              let nonce = UInt32(nonceHex, radix: 16) else {
            throw GiftError.invalidFormat
        }
        let expected = sign(amount: amount, nonce: nonce)
        guard expected.lowercased() == sigHex.lowercased() else {
            throw GiftError.invalidSignature
        }
        if ownGiftNonces().contains(nonce) {
            throw GiftError.selfRedeemBlocked
        }
        var redeemed = redeemedNonces()
        if redeemed.contains(nonce) {
            throw GiftError.alreadyRedeemed
        }
        redeemed.insert(nonce)
        saveRedeemedNonces(redeemed)
        CoinManager.shared.addCoins(Int(amount))
        return Int(amount)
    }

    // MARK: - Encoding

    private func encode(amount: UInt16, nonce: UInt32) -> String {
        let amountHex = String(format: "%04X", amount)
        let nonceHex = String(format: "%08X", nonce)
        let nonceBlock1 = String(nonceHex.prefix(4))
        let nonceBlock2 = String(nonceHex.suffix(4))
        let sig = sign(amount: amount, nonce: nonce)
        return "\(prefix)-\(amountHex)-\(nonceBlock1)-\(nonceBlock2)-\(sig)"
    }

    private func sign(amount: UInt16, nonce: UInt32) -> String {
        var data = Data()
        var amt = amount.bigEndian
        var n = nonce.bigEndian
        withUnsafeBytes(of: &amt) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: &n) { data.append(contentsOf: $0) }
        let key = SymmetricKey(data: Data(secret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: data, using: key)
        let macBytes = Data(mac).prefix(2)
        return macBytes.map { String(format: "%02X", $0) }.joined()
    }

    // MARK: - Nonce tracking

    private func redeemedNonces() -> Set<UInt32> {
        let raw = UserDefaults.standard.array(forKey: redeemedNoncesKey) as? [UInt] ?? []
        return Set(raw.map { UInt32(truncatingIfNeeded: $0) })
    }
    private func saveRedeemedNonces(_ set: Set<UInt32>) {
        UserDefaults.standard.set(set.map { UInt($0) }, forKey: redeemedNoncesKey)
    }

    private let ownGiftNoncesKey = "ownGiftNonces"
    private func ownGiftNonces() -> Set<UInt32> {
        let raw = UserDefaults.standard.array(forKey: ownGiftNoncesKey) as? [UInt] ?? []
        return Set(raw.map { UInt32(truncatingIfNeeded: $0) })
    }
    private func recordOwnGiftNonce(_ nonce: UInt32) {
        var nonces = ownGiftNonces()
        nonces.insert(nonce)
        UserDefaults.standard.set(nonces.map { UInt($0) }, forKey: ownGiftNoncesKey)
    }

    // MARK: - Suggested amounts for the gift picker

    static let suggestedAmounts = [50, 100, 250, 500]
}
