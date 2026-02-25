//
//  GomokuGameModel.swift
//  Gomoku
//
//  GameplayKit integration — GKGameModelPlayer, GKGameModelUpdate,
//  and GKGameModel implementations that bridge the existing GomokuBoard
//  engine to GameplayKit's strategist infrastructure.
//

import GameplayKit

// MARK: - GKGameModelPlayer

/// Wraps the `Player` enum so GameplayKit strategists can identify participants.
class GomokuPlayer: NSObject, GKGameModelPlayer {
    let playerId: Int
    let player: Player

    static let blackPlayer = GomokuPlayer(player: .black, id: 0)
    static let whitePlayer = GomokuPlayer(player: .white, id: 1)

    private init(player: Player, id: Int) {
        self.player = player
        self.playerId = id
        super.init()
    }

    /// Convert a `Player` enum value to the corresponding `GomokuPlayer` singleton.
    static func from(_ player: Player) -> GomokuPlayer {
        switch player {
        case .black: return blackPlayer
        case .white: return whitePlayer
        case .none:  return blackPlayer
        }
    }
}

// MARK: - GKGameModelUpdate

/// A single candidate move that GameplayKit strategists can evaluate.
class GomokuMove: NSObject, GKGameModelUpdate {
    /// Heuristic value assigned by the strategist during search.
    var value: Int = 0
    let row: Int
    let col: Int

    init(row: Int, col: Int) {
        self.row = row
        self.col = col
        super.init()
    }

    override var description: String {
        return "GomokuMove(\(row), \(col)) value=\(value)"
    }
}

// MARK: - GKGameModel

/// Adapts `GomokuBoard` to the `GKGameModel` protocol so that
/// `GKMinmaxStrategist` and `GKMonteCarloStrategist` can search the game tree.
class GomokuGameModel: NSObject, GKGameModel {

    /// The underlying board state.
    private(set) var board: GomokuBoard

    /// Maximum number of candidate moves returned by `gameModelUpdates(for:)`.
    /// Smaller values speed up the search at the cost of potentially missing moves.
    var candidateLimit: Int = 20

    // MARK: GKGameModel — Properties

    var players: [GKGameModelPlayer]? {
        return [GomokuPlayer.blackPlayer, GomokuPlayer.whitePlayer]
    }

    var activePlayer: GKGameModelPlayer? {
        guard case .playing = board.gameState else { return nil }
        return GomokuPlayer.from(board.currentPlayer)
    }

    // MARK: Initialisation

    init(board: GomokuBoard) {
        self.board = GomokuBoard(copying: board)
        super.init()
    }

    // MARK: NSCopying

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = GomokuGameModel(board: board)
        copy.candidateLimit = candidateLimit
        return copy
    }

    // MARK: GKGameModel — State Management

    func setGameModel(_ gameModel: GKGameModel) {
        guard let model = gameModel as? GomokuGameModel else { return }
        self.board = GomokuBoard(copying: model.board)
    }

    // MARK: GKGameModel — Move Generation

    func gameModelUpdates(for player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
        guard case .playing = board.gameState else { return nil }

        var candidates = getCandidateMoves()
        if candidates.isEmpty { return nil }

        // Sort by quick heuristic for better alpha-beta pruning
        let current = board.currentPlayer
        candidates.sort { a, b in
            quickEvaluate(row: a.row, col: a.col, player: current) >
            quickEvaluate(row: b.row, col: b.col, player: current)
        }

        let limited = Array(candidates.prefix(candidateLimit))
        return limited.map { GomokuMove(row: $0.row, col: $0.col) }
    }

    // MARK: GKGameModel — Apply

    func apply(_ gameModelUpdate: GKGameModelUpdate) {
        guard let move = gameModelUpdate as? GomokuMove else { return }
        _ = board.placeStone(at: move.row, col: move.col)
    }

    // MARK: GKGameModel — Evaluation

    func score(for player: GKGameModelPlayer) -> Int {
        guard let gkPlayer = player as? GomokuPlayer else { return 0 }
        return evaluateBoard(for: gkPlayer.player)
    }

    func isWin(for player: GKGameModelPlayer) -> Bool {
        guard let gkPlayer = player as? GomokuPlayer else { return false }
        if case .won(let winner) = board.gameState {
            return winner == gkPlayer.player
        }
        return false
    }

    func isLoss(for player: GKGameModelPlayer) -> Bool {
        guard let gkPlayer = player as? GomokuPlayer else { return false }
        if case .won(let winner) = board.gameState {
            return winner != gkPlayer.player
        }
        return false
    }

    // MARK: - Candidate Move Generation (private)

    private func getCandidateMoves() -> [(row: Int, col: Int)] {
        var candidates: Set<Int> = []
        let range = 2
        let size = board.size

        for row in 0..<size {
            for col in 0..<size {
                if board.getPlayer(at: row, col: col) != .none {
                    for dr in -range...range {
                        for dc in -range...range {
                            let r = row + dr
                            let c = col + dc
                            if r >= 0 && r < size && c >= 0 && c < size &&
                               board.getPlayer(at: r, col: c) == .none {
                                candidates.insert(r * size + c)
                            }
                        }
                    }
                }
            }
        }

        // First move — offer the center neighbourhood
        if candidates.isEmpty {
            let center = size / 2
            for dr in -1...1 {
                for dc in -1...1 {
                    candidates.insert((center + dr) * size + (center + dc))
                }
            }
        }

        return candidates.map { hash in
            (row: hash / size, col: hash % size)
        }
    }

    // MARK: - Board Evaluation (private)

    private func evaluateBoard(for player: Player) -> Int {
        var score = 0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        let size = board.size

        for row in 0..<size {
            for col in 0..<size {
                for (dx, dy) in directions {
                    let pattern = analyzeLine(row: row, col: col, dx: dx, dy: dy, player: player)
                    score += scorePattern(pattern)

                    let oppPattern = analyzeLine(row: row, col: col, dx: dx, dy: dy, player: player.opposite)
                    score -= scorePattern(oppPattern)
                }
            }
        }

        // Center control bonus
        let center = size / 2
        for row in 0..<size {
            for col in 0..<size {
                let p = board.getPlayer(at: row, col: col)
                if p == player {
                    let dist = abs(row - center) + abs(col - center)
                    score += max(0, 10 - dist)
                } else if p == player.opposite {
                    let dist = abs(row - center) + abs(col - center)
                    score -= max(0, 8 - dist)
                }
            }
        }

        return score
    }

    private func quickEvaluate(row: Int, col: Int, player: Player) -> Int {
        var score = 0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]

        for (dx, dy) in directions {
            let pattern = analyzeLine(row: row, col: col, dx: dx, dy: dy, player: player)
            score += scorePattern(pattern) / 10

            let oppPattern = analyzeLine(row: row, col: col, dx: dx, dy: dy, player: player.opposite)
            score += scorePattern(oppPattern) / 10
        }

        return score
    }

    private func analyzeLine(row: Int, col: Int, dx: Int, dy: Int, player: Player) -> (count: Int, openEnds: Int) {
        var count = 0
        var openEnds = 0
        let size = board.size

        var r = row, c = col
        while r >= 0 && r < size && c >= 0 && c < size && board.getPlayer(at: r, col: c) == player {
            count += 1; r += dx; c += dy
        }
        if r >= 0 && r < size && c >= 0 && c < size && board.getPlayer(at: r, col: c) == .none {
            openEnds += 1
        }

        r = row - dx; c = col - dy
        while r >= 0 && r < size && c >= 0 && c < size && board.getPlayer(at: r, col: c) == player {
            count += 1; r -= dx; c -= dy
        }
        if r >= 0 && r < size && c >= 0 && c < size && board.getPlayer(at: r, col: c) == .none {
            openEnds += 1
        }

        return (count, openEnds)
    }

    private func scorePattern(_ pattern: (count: Int, openEnds: Int)) -> Int {
        let (count, openEnds) = pattern
        switch count {
        case 5...:
            return 100000
        case 4:
            if openEnds == 2 { return 50000 }
            if openEnds == 1 { return 1000 }
        case 3:
            if openEnds == 2 { return 5000 }
            if openEnds == 1 { return 200 }
        case 2:
            if openEnds == 2 { return 150 }
            if openEnds == 1 { return 15 }
        case 1:
            if openEnds == 2 { return 10 }
        default:
            break
        }
        return 0
    }
}
