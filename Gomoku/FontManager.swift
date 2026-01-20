//
//  FontManager.swift
//  Gomoku
//
//  Manages responsive font sizing across different device sizes
//  and supports iOS Dynamic Type accessibility settings.
//

import SpriteKit
import UIKit

/// Font size categories for consistent typography throughout the app
enum FontSize {
    case largeTitle     // Screen titles (e.g., "Settings", "Statistics")
    case title          // Section titles, dialog headers
    case title2         // Secondary titles
    case headline       // Button labels, important text
    case body           // Standard text
    case callout        // Supporting text
    case subheadline    // Subtitles, descriptions
    case footnote       // Small labels, hints
    case caption        // Very small text (badges, tags)
    case caption2       // Smallest text

    /// Base font size for iPhone SE / small devices (320pt width)
    var baseSize: CGFloat {
        switch self {
        case .largeTitle:   return 28
        case .title:        return 22
        case .title2:       return 20
        case .headline:     return 17
        case .body:         return 15
        case .callout:      return 14
        case .subheadline:  return 13
        case .footnote:     return 12
        case .caption:      return 11
        case .caption2:     return 10
        }
    }
}

/// Manages font scaling based on device size and accessibility settings
class FontManager {
    static let shared = FontManager()

    // MARK: - Properties

    /// Current screen scale factor based on device size
    private(set) var scaleFactor: CGFloat = 1.0

    /// Dynamic Type scale factor from accessibility settings
    private(set) var dynamicTypeScale: CGFloat = 1.0

    /// Reference screen width (iPhone SE)
    private let referenceWidth: CGFloat = 320

    /// Maximum screen width for scaling (iPad Pro 12.9")
    private let maxReferenceWidth: CGFloat = 1024

    /// Minimum scale factor to prevent text from becoming too small
    private let minScaleFactor: CGFloat = 0.85

    /// Maximum scale factor to prevent text from becoming too large
    private let maxScaleFactor: CGFloat = 1.6

    /// Maximum Dynamic Type scale to ensure UI remains usable
    private let maxDynamicTypeScale: CGFloat = 1.5

    // MARK: - Initialization

    private init() {
        updateScaleFactors()

        // Listen for Dynamic Type changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentSizeCategoryDidChange),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// Updates scale factors based on current screen size
    /// Call this when the scene size changes or on app launch
    func updateForScreenSize(_ size: CGSize) {
        let screenWidth = max(size.width, size.height)

        // Calculate scale based on screen width relative to reference
        // Use square root for more subtle scaling on larger devices
        let rawScale = sqrt(screenWidth / referenceWidth)

        // Clamp to reasonable bounds
        scaleFactor = max(minScaleFactor, min(rawScale, maxScaleFactor))

        // Post notification for scenes to update
        NotificationCenter.default.post(name: .fontScaleDidChange, object: nil)
    }

    /// Returns the scaled font size for a given category
    func size(for category: FontSize) -> CGFloat {
        let baseSize = category.baseSize
        let scaled = baseSize * scaleFactor * dynamicTypeScale

        // Round to nearest 0.5 for crisp rendering
        return (scaled * 2).rounded() / 2
    }

    /// Returns a custom scaled size (for cases that don't fit standard categories)
    func scaledSize(_ baseSize: CGFloat) -> CGFloat {
        let scaled = baseSize * scaleFactor * dynamicTypeScale
        return (scaled * 2).rounded() / 2
    }

    /// Returns a scaled size that ignores Dynamic Type (for fixed UI elements)
    func fixedScaledSize(_ baseSize: CGFloat) -> CGFloat {
        let scaled = baseSize * scaleFactor
        return (scaled * 2).rounded() / 2
    }

    /// Returns the combined scale factor (screen + Dynamic Type)
    var combinedScale: CGFloat {
        return scaleFactor * dynamicTypeScale
    }

    // MARK: - Convenience Methods for SKLabelNode

    /// Creates a label with the appropriate scaled font size
    func createLabel(
        text: String,
        category: FontSize,
        fontName: String = "AvenirNext-Medium"
    ) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.text = text
        label.fontSize = size(for: category)
        return label
    }

    /// Updates an existing label's font size
    func updateLabelSize(_ label: SKLabelNode, category: FontSize) {
        label.fontSize = size(for: category)
    }

    // MARK: - Private Methods

    private func updateScaleFactors() {
        // Get current screen size
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let screenSize = window.bounds.size
            let screenWidth = max(screenSize.width, screenSize.height)
            let rawScale = sqrt(screenWidth / referenceWidth)
            scaleFactor = max(minScaleFactor, min(rawScale, maxScaleFactor))
        }

        // Get Dynamic Type preference
        updateDynamicTypeScale()
    }

    private func updateDynamicTypeScale() {
        let category = UIApplication.shared.preferredContentSizeCategory

        // Map content size categories to scale factors
        switch category {
        case .extraSmall:
            dynamicTypeScale = 0.82
        case .small:
            dynamicTypeScale = 0.88
        case .medium:
            dynamicTypeScale = 0.94
        case .large: // Default
            dynamicTypeScale = 1.0
        case .extraLarge:
            dynamicTypeScale = 1.06
        case .extraExtraLarge:
            dynamicTypeScale = 1.12
        case .extraExtraExtraLarge:
            dynamicTypeScale = 1.18
        case .accessibilityMedium:
            dynamicTypeScale = 1.24
        case .accessibilityLarge:
            dynamicTypeScale = 1.32
        case .accessibilityExtraLarge:
            dynamicTypeScale = 1.40
        case .accessibilityExtraExtraLarge:
            dynamicTypeScale = 1.45
        case .accessibilityExtraExtraExtraLarge:
            dynamicTypeScale = 1.50
        default:
            dynamicTypeScale = 1.0
        }

        // Apply maximum cap
        dynamicTypeScale = min(dynamicTypeScale, maxDynamicTypeScale)
    }

    @objc private func contentSizeCategoryDidChange() {
        updateDynamicTypeScale()
        NotificationCenter.default.post(name: .fontScaleDidChange, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let fontScaleDidChange = Notification.Name("fontScaleDidChange")
}

// MARK: - SKScene Extension for Font Scaling

extension SKScene {
    /// Call this in didMove(to:) to initialize font scaling for this scene
    func initializeFontScaling() {
        FontManager.shared.updateForScreenSize(size)
    }

    /// Convenience property to access FontManager
    var fontManager: FontManager {
        return FontManager.shared
    }

    /// Convenience method to get scaled font size
    func fontSize(_ category: FontSize) -> CGFloat {
        return FontManager.shared.size(for: category)
    }

    /// Convenience method to get custom scaled size
    func scaledFontSize(_ baseSize: CGFloat) -> CGFloat {
        return FontManager.shared.scaledSize(baseSize)
    }
}

// MARK: - SKLabelNode Extension

extension SKLabelNode {
    /// Sets the font size using the FontManager scaling
    func setScaledFontSize(_ category: FontSize) {
        self.fontSize = FontManager.shared.size(for: category)
    }

    /// Sets a custom scaled font size
    func setScaledFontSize(base: CGFloat) {
        self.fontSize = FontManager.shared.scaledSize(base)
    }
}
