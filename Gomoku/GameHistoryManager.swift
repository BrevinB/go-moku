//
//  GameHistoryManager.swift
//  Gomoku
//
//  Manages persistence of completed games for replay functionality.
//

import Foundation

class GameHistoryManager {
    static let shared = GameHistoryManager()
    private let key = "completedGamesHistory"
    private let maxStoredGames = 10

    private(set) var games: [CompletedGame] = []

    private init() {
        loadGames()
    }

    var hasGames: Bool {
        !games.isEmpty
    }

    var gameCount: Int {
        games.count
    }

    func getGame(id: UUID) -> CompletedGame? {
        games.first { $0.id == id }
    }

    func saveCompletedGame(board: GomokuBoard, gameMode: GameMode, aiDifficulty: AIDifficulty, humanPlayer: Player, winner: Player) {
        let moveHistory = board.getMoveHistory()

        let encodedMoves = moveHistory.map { move in
            CompletedGame.EncodedMove(
                row: move.row,
                col: move.col,
                playerIndex: move.player == .black ? 0 : 1
            )
        }

        let completedGame = CompletedGame(
            id: UUID(),
            moves: encodedMoves,
            boardSize: board.size,
            gameMode: gameMode,
            aiDifficulty: gameMode == .vsAI ? aiDifficulty : nil,
            humanPlayer: gameMode == .vsAI ? humanPlayer : nil,
            winner: winner,
            completedAt: Date(),
            moveCount: moveHistory.count
        )

        addCompletedGame(completedGame)
    }

    private func addCompletedGame(_ game: CompletedGame) {
        // Insert at the front (newest first)
        games.insert(game, at: 0)

        // Trim to max stored games
        if games.count > maxStoredGames {
            games = Array(games.prefix(maxStoredGames))
        }

        persistGames()
    }

    private func loadGames() {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            games = []
            return
        }

        do {
            games = try JSONDecoder().decode([CompletedGame].self, from: data)
        } catch {
            print("GameHistoryManager: Failed to decode games - \(error.localizedDescription)")
            games = []
        }
    }

    private func persistGames() {
        do {
            let encoded = try JSONEncoder().encode(games)
            UserDefaults.standard.set(encoded, forKey: key)
        } catch {
            print("GameHistoryManager: Failed to encode games - \(error.localizedDescription)")
        }
    }

    func clearAllGames() {
        games.removeAll()
        UserDefaults.standard.removeObject(forKey: key)
    }
}
