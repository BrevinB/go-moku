//
//  GameStateManager.swift
//  Gomoku
//
//  Created by Claude on 12/26/25.
//

import Foundation

struct SavedGame: Codable {
    let moves: [EncodedMove]
    let boardSize: Int
    let gameMode: GameMode
    let aiDifficulty: AIDifficulty
    let humanPlayer: Player
    let savedAt: Date

    struct EncodedMove: Codable {
        let row: Int
        let col: Int
        let playerIndex: Int  // 0 = black, 1 = white
    }
}

class GameStateManager {
    static let shared = GameStateManager()
    private let key = "savedGomokuGame"

    private init() {}

    var hasSavedGame: Bool {
        UserDefaults.standard.data(forKey: key) != nil
    }

    func loadSavedGame() -> SavedGame? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(SavedGame.self, from: data)
        } catch {
            print("GameStateManager: Failed to decode saved game - \(error.localizedDescription)")
            clearSavedGame()
            return nil
        }
    }

    func saveGame(board: GomokuBoard, gameMode: GameMode, aiDifficulty: AIDifficulty, humanPlayer: Player) {
        // Only save if game is still in progress
        guard case .playing = board.gameState else {
            clearSavedGame()
            return
        }

        // Convert moves to encodable format
        let encodedMoves = board.getMoveHistory().map { move in
            SavedGame.EncodedMove(
                row: move.row,
                col: move.col,
                playerIndex: move.player == .black ? 0 : 1
            )
        }

        let savedGame = SavedGame(
            moves: encodedMoves,
            boardSize: board.size,
            gameMode: gameMode,
            aiDifficulty: aiDifficulty,
            humanPlayer: humanPlayer,
            savedAt: Date()
        )

        do {
            let encoded = try JSONEncoder().encode(savedGame)
            UserDefaults.standard.set(encoded, forKey: key)
        } catch {
            print("GameStateManager: Failed to encode saved game - \(error.localizedDescription)")
        }
    }

    func clearSavedGame() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
