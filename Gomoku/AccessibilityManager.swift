//
//  AccessibilityManager.swift
//  Gomoku
//
//  Manages accessibility settings including colorblind mode.
//

import Foundation
import SpriteKit

class AccessibilityManager {
    static let shared = AccessibilityManager()

    // UserDefaults keys
    private let colorblindModeKey = "colorblindModeEnabled"
    private let reduceMotionKey = "reduceMotionEnabled"
    private let showCoordinatesKey = "showBoardCoordinates"
    private let highContrastKey = "highContrastEnabled"

    // MARK: - Settings

    private(set) var isColorblindModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isColorblindModeEnabled, forKey: colorblindModeKey)
            NotificationCenter.default.post(name: .accessibilitySettingsChanged, object: nil)
        }
    }

    private(set) var isReduceMotionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isReduceMotionEnabled, forKey: reduceMotionKey)
            NotificationCenter.default.post(name: .accessibilitySettingsChanged, object: nil)
        }
    }

    private(set) var showBoardCoordinates: Bool {
        didSet {
            UserDefaults.standard.set(showBoardCoordinates, forKey: showCoordinatesKey)
            NotificationCenter.default.post(name: .accessibilitySettingsChanged, object: nil)
        }
    }

    private(set) var isHighContrastEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHighContrastEnabled, forKey: highContrastKey)
            NotificationCenter.default.post(name: .accessibilitySettingsChanged, object: nil)
        }
    }

    private init() {
        isColorblindModeEnabled = UserDefaults.standard.bool(forKey: colorblindModeKey)
        isReduceMotionEnabled = UserDefaults.standard.bool(forKey: reduceMotionKey)
        showBoardCoordinates = UserDefaults.standard.bool(forKey: showCoordinatesKey)
        isHighContrastEnabled = UserDefaults.standard.bool(forKey: highContrastKey)
    }

    // MARK: - Setters

    func setColorblindMode(_ enabled: Bool) {
        isColorblindModeEnabled = enabled
    }

    func setReduceMotion(_ enabled: Bool) {
        isReduceMotionEnabled = enabled
    }

    func setShowCoordinates(_ enabled: Bool) {
        showBoardCoordinates = enabled
    }

    func setHighContrast(_ enabled: Bool) {
        isHighContrastEnabled = enabled
    }

    // MARK: - Animation Helpers

    /// Returns the appropriate animation duration based on reduce motion setting
    func animationDuration(_ normalDuration: TimeInterval) -> TimeInterval {
        return isReduceMotionEnabled ? 0.05 : normalDuration
    }

    /// Returns whether animations should be skipped entirely
    var shouldSkipAnimations: Bool {
        return isReduceMotionEnabled
    }

    // MARK: - High Contrast Helpers

    /// Returns enhanced line width for high contrast mode
    func lineWidth(_ normalWidth: CGFloat) -> CGFloat {
        return isHighContrastEnabled ? normalWidth * 1.5 : normalWidth
    }

    /// Returns enhanced stroke alpha for high contrast mode
    func strokeAlpha(_ normalAlpha: CGFloat) -> CGFloat {
        return isHighContrastEnabled ? min(normalAlpha * 1.5, 1.0) : normalAlpha
    }

    // MARK: - Stone Marker Creation

    /// Adds a colorblind-friendly marker to a stone node
    /// - Parameters:
    ///   - stone: The stone shape node to add the marker to
    ///   - player: The player (black or white) to determine marker style
    ///   - radius: The radius of the stone for sizing the marker
    func addColorblindMarker(to stone: SKShapeNode, player: Player, radius: CGFloat) {
        guard isColorblindModeEnabled else { return }

        // Remove any existing marker
        stone.childNode(withName: "colorblindMarker")?.removeFromParent()

        let markerSize = radius * 0.5

        if player == .black {
            // Add X marker for black stones
            addCrossMarker(to: stone, size: markerSize, color: .white)
        } else {
            // Add O marker for white stones
            addCircleMarker(to: stone, size: markerSize, color: .black)
        }
    }

    private func addCrossMarker(to stone: SKShapeNode, size: CGFloat, color: SKColor) {
        let marker = SKNode()
        marker.name = "colorblindMarker"
        marker.zPosition = 10

        // Create X shape using two lines
        let line1 = SKShapeNode()
        let path1 = CGMutablePath()
        path1.move(to: CGPoint(x: -size, y: -size))
        path1.addLine(to: CGPoint(x: size, y: size))
        line1.path = path1
        line1.strokeColor = color
        line1.lineWidth = size * 0.35
        line1.lineCap = .round
        marker.addChild(line1)

        let line2 = SKShapeNode()
        let path2 = CGMutablePath()
        path2.move(to: CGPoint(x: size, y: -size))
        path2.addLine(to: CGPoint(x: -size, y: size))
        line2.path = path2
        line2.strokeColor = color
        line2.lineWidth = size * 0.35
        line2.lineCap = .round
        marker.addChild(line2)

        stone.addChild(marker)
    }

    private func addCircleMarker(to stone: SKShapeNode, size: CGFloat, color: SKColor) {
        let marker = SKShapeNode(circleOfRadius: size)
        marker.name = "colorblindMarker"
        marker.fillColor = .clear
        marker.strokeColor = color
        marker.lineWidth = size * 0.35
        marker.zPosition = 10
        marker.position = .zero

        stone.addChild(marker)
    }

    /// Creates a standalone marker node (for use when stone is created differently)
    func createMarkerNode(for player: Player, radius: CGFloat) -> SKNode? {
        guard isColorblindModeEnabled else { return nil }

        let markerSize = radius * 0.5

        if player == .black {
            return createCrossMarkerNode(size: markerSize, color: .white)
        } else {
            return createCircleMarkerNode(size: markerSize, color: .black)
        }
    }

    private func createCrossMarkerNode(size: CGFloat, color: SKColor) -> SKNode {
        let marker = SKNode()
        marker.name = "colorblindMarker"
        marker.zPosition = 10

        let line1 = SKShapeNode()
        let path1 = CGMutablePath()
        path1.move(to: CGPoint(x: -size, y: -size))
        path1.addLine(to: CGPoint(x: size, y: size))
        line1.path = path1
        line1.strokeColor = color
        line1.lineWidth = size * 0.35
        line1.lineCap = .round
        marker.addChild(line1)

        let line2 = SKShapeNode()
        let path2 = CGMutablePath()
        path2.move(to: CGPoint(x: size, y: -size))
        path2.addLine(to: CGPoint(x: -size, y: size))
        line2.path = path2
        line2.strokeColor = color
        line2.lineWidth = size * 0.35
        line2.lineCap = .round
        marker.addChild(line2)

        return marker
    }

    private func createCircleMarkerNode(size: CGFloat, color: SKColor) -> SKNode {
        let marker = SKShapeNode(circleOfRadius: size)
        marker.name = "colorblindMarker"
        marker.fillColor = .clear
        marker.strokeColor = color
        marker.lineWidth = size * 0.35
        marker.zPosition = 10
        marker.position = .zero

        return marker
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let accessibilitySettingsChanged = Notification.Name("accessibilitySettingsChanged")
}
