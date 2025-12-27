//
//  SoundManager.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import AVFoundation
import UIKit

class SoundManager {
    static let shared = SoundManager()

    private var soundEnabled = true
    private var hapticsEnabled = true

    // Haptic feedback generators
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // Audio players for different sounds
    private var stonePlacePlayer: AVAudioPlayer?
    private var winPlayer: AVAudioPlayer?
    private var buttonPlayer: AVAudioPlayer?

    private init() {
        // Load saved preferences
        soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true

        setupAudioSession()
        prepareHaptics()
        loadSounds()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func prepareHaptics() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }

    private func loadSounds() {
        // For now, we'll use system sounds
        // In production, you would load custom sound files here
        // Example:
        // if let url = Bundle.main.url(forResource: "stone_place", withExtension: "wav") {
        //     stonePlacePlayer = try? AVAudioPlayer(contentsOf: url)
        //     stonePlacePlayer?.prepareToPlay()
        // }
    }

    // MARK: - Public Methods

    func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "soundEnabled")
    }

    func setHapticsEnabled(_ enabled: Bool) {
        hapticsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "hapticsEnabled")
    }

    func isSoundEnabled() -> Bool {
        return soundEnabled
    }

    func isHapticsEnabled() -> Bool {
        return hapticsEnabled
    }

    // MARK: - Sound Effects

    func playStonePlace() {
        guard soundEnabled else { return }

        // Use system sound for now
        AudioServicesPlaySystemSound(1306) // Keyboard tap sound

        // If you have custom sound:
        // stonePlacePlayer?.play()
    }

    func playWin() {
        guard soundEnabled else { return }

        // Use system sound for celebration
        AudioServicesPlaySystemSound(1025) // Success sound

        // If you have custom sound:
        // winPlayer?.play()
    }

    func playButton() {
        guard soundEnabled else { return }

        // Use system sound for button
        AudioServicesPlaySystemSound(1104) // Button click

        // If you have custom sound:
        // buttonPlayer?.play()
    }

    // MARK: - Haptic Feedback

    func hapticLight() {
        guard hapticsEnabled else { return }
        lightImpact.impactOccurred()
    }

    func hapticMedium() {
        guard hapticsEnabled else { return }
        mediumImpact.impactOccurred()
    }

    func hapticHeavy() {
        guard hapticsEnabled else { return }
        heavyImpact.impactOccurred()
    }

    func hapticSelection() {
        guard hapticsEnabled else { return }
        selectionFeedback.selectionChanged()
    }

    func hapticSuccess() {
        guard hapticsEnabled else { return }
        notificationFeedback.notificationOccurred(.success)
    }

    func hapticWarning() {
        guard hapticsEnabled else { return }
        notificationFeedback.notificationOccurred(.warning)
    }

    func hapticError() {
        guard hapticsEnabled else { return }
        notificationFeedback.notificationOccurred(.error)
    }

    // Combined effects for common actions
    func stonePlaced() {
        playStonePlace()
        hapticMedium()
    }

    func gameWon() {
        playWin()
        hapticSuccess()
    }

    func buttonTapped() {
        playButton()
        hapticLight()
    }
}
