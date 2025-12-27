//
//  CompletedGame.swift
//  Gomoku
//
//  Data structure for storing finished games for replay.
//

import Foundation

struct CompletedGame: Codable, Identifiable {
    let id: UUID
    let moves: [EncodedMove]
    let boardSize: Int
    let gameMode: GameMode
    let aiDifficulty: AIDifficulty?
    let humanPlayer: Player?
    let winner: Player
    let completedAt: Date
    let moveCount: Int

    struct EncodedMove: Codable {
        let row: Int
        let col: Int
        let playerIndex: Int  // 0 = black, 1 = white

        var player: Player {
            playerIndex == 0 ? .black : .white
        }
    }

    var resultDescription: String {
        switch winner {
        case .black:
            if gameMode == .vsAI, let human = humanPlayer {
                return human == .black ? "You Won" : "AI Won"
            }
            return "Black Won"
        case .white:
            if gameMode == .vsAI, let human = humanPlayer {
                return human == .white ? "You Won" : "AI Won"
            }
            return "White Won"
        case .none:
            return "Draw"
        }
    }

    var colorDescription: String? {
        guard gameMode == .vsAI, let human = humanPlayer else { return nil }
        return "You played as \(human == .black ? "Black" : "White")"
    }

    var modeDescription: String {
        switch gameMode {
        case .vsAI:
            if let difficulty = aiDifficulty {
                return "VS AI (\(difficulty.rawValue.capitalized))"
            }
            return "VS AI"
        case .twoPlayer:
            return "VS Friend"
        }
    }

    var dateDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: completedAt)
    }
}
