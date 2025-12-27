//
//  GomokuBoard.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import Foundation

enum Player {
    case black
    case white
    case none

    var opposite: Player {
        switch self {
        case .black: return .white
        case .white: return .black
        case .none: return .none
        }
    }
}

enum GameState {
    case playing
    case won(Player)
    case draw
}

struct Move {
    let row: Int
    let col: Int
    let player: Player
}

class GomokuBoard {
    let size: Int
    private var board: [[Player]]
    var currentPlayer: Player
    var gameState: GameState
    private var moveHistory: [Move] = []
    var winningPositions: [(Int, Int)] = []

    init(size: Int = 15) {
        self.size = size
        self.board = Array(repeating: Array(repeating: .none, count: size), count: size)
        self.currentPlayer = .black
        self.gameState = .playing
    }

    // Copy initializer for AI simulations
    init(copying other: GomokuBoard) {
        self.size = other.size
        self.board = other.board
        self.currentPlayer = other.currentPlayer
        self.gameState = other.gameState
        self.moveHistory = other.moveHistory
    }

    func canUndo() -> Bool {
        return !moveHistory.isEmpty
    }

    func getMoveHistory() -> [Move] {
        return moveHistory
    }

    func getPlayer(at row: Int, col: Int) -> Player {
        guard isValid(row: row, col: col) else { return .none }
        return board[row][col]
    }

    func placeStone(at row: Int, col: Int) -> Bool {
        guard case .playing = gameState else { return false }
        guard isValid(row: row, col: col) else { return false }
        guard board[row][col] == .none else { return false }

        // Record the move
        let move = Move(row: row, col: col, player: currentPlayer)
        moveHistory.append(move)

        board[row][col] = currentPlayer

        if checkWin(at: row, col: col) {
            gameState = .won(currentPlayer)
        } else if isBoardFull() {
            gameState = .draw
        } else {
            currentPlayer = currentPlayer.opposite
        }

        return true
    }

    func undoMove() -> Move? {
        guard let lastMove = moveHistory.popLast() else { return nil }

        // Remove the stone from the board
        board[lastMove.row][lastMove.col] = .none

        // Restore game state to playing if it was won or draw
        gameState = .playing

        // Set current player back to the player who made the move
        currentPlayer = lastMove.player

        return lastMove
    }

    func reset() {
        board = Array(repeating: Array(repeating: .none, count: size), count: size)
        currentPlayer = .black
        gameState = .playing
        moveHistory.removeAll()
        winningPositions.removeAll()
    }

    private func isValid(row: Int, col: Int) -> Bool {
        return row >= 0 && row < size && col >= 0 && col < size
    }

    private func isBoardFull() -> Bool {
        for row in 0..<size {
            for col in 0..<size {
                if board[row][col] == .none {
                    return false
                }
            }
        }
        return true
    }

    private func checkWin(at row: Int, col: Int) -> Bool {
        let player = board[row][col]
        let directions = [
            (0, 1),   // horizontal
            (1, 0),   // vertical
            (1, 1),   // diagonal \
            (1, -1)   // diagonal /
        ]

        for (dx, dy) in directions {
            var count = 1
            var positions = [(row, col)]

            // Check positive direction
            var r = row + dx
            var c = col + dy
            while isValid(row: r, col: c) && board[r][c] == player {
                positions.append((r, c))
                count += 1
                r += dx
                c += dy
            }

            // Check negative direction
            r = row - dx
            c = col - dy
            while isValid(row: r, col: c) && board[r][c] == player {
                positions.append((r, c))
                count += 1
                r -= dx
                c -= dy
            }

            if count >= 5 {
                winningPositions = positions
                return true
            }
        }

        return false
    }
}

