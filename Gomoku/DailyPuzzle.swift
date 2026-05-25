//
//  DailyPuzzle.swift
//  Gomoku
//
//  Hand-curated single-move puzzles. The bank rotates by day so all players see
//  the same puzzle each day; adding new puzzles just extends the bank.
//

import Foundation

struct DailyPuzzle {
    struct PlacedStone {
        let row: Int
        let col: Int
        let player: Player
    }

    let id: String
    let title: String
    let stones: [PlacedStone]
    let playerToMove: Player
    /// All moves that result in 5-in-a-row for `playerToMove` from this position.
    let winningMoves: [(row: Int, col: Int)]
    let reward: Int
}

extension DailyPuzzle {
    /// Pick today's puzzle. Stable for everyone in the same time zone.
    static func todaysPuzzle() -> DailyPuzzle {
        let days = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        let index = days % bank.count
        return bank[index]
    }

    /// Built one at a time so the Swift type-checker doesn't blow up on a giant literal.
    static let bank: [DailyPuzzle] = makeBank()

    private static func makeBank() -> [DailyPuzzle] {
        var bank: [DailyPuzzle] = []

        // 1: Horizontal four with one blocked end
        var stones: [PlacedStone] = []
        stones.append(PlacedStone(row: 7, col: 3, player: .white))
        stones.append(PlacedStone(row: 7, col: 4, player: .black))
        stones.append(PlacedStone(row: 7, col: 5, player: .black))
        stones.append(PlacedStone(row: 7, col: 6, player: .black))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        bank.append(DailyPuzzle(
            id: "h-block-east", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 7, col: 8)], reward: 50
        ))

        // 2: Diagonal four blocked NW
        stones = []
        stones.append(PlacedStone(row: 3, col: 3, player: .white))
        stones.append(PlacedStone(row: 4, col: 4, player: .black))
        stones.append(PlacedStone(row: 5, col: 5, player: .black))
        stones.append(PlacedStone(row: 6, col: 6, player: .black))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        bank.append(DailyPuzzle(
            id: "diag-block-nw", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 8, col: 8)], reward: 50
        ))

        // 3: Vertical four blocked top
        stones = []
        stones.append(PlacedStone(row: 3, col: 7, player: .white))
        stones.append(PlacedStone(row: 4, col: 7, player: .black))
        stones.append(PlacedStone(row: 5, col: 7, player: .black))
        stones.append(PlacedStone(row: 6, col: 7, player: .black))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        bank.append(DailyPuzzle(
            id: "v-block-top", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 8, col: 7)], reward: 50
        ))

        // 4: Open four — either end wins
        stones = []
        stones.append(PlacedStone(row: 7, col: 5, player: .black))
        stones.append(PlacedStone(row: 7, col: 6, player: .black))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        stones.append(PlacedStone(row: 7, col: 8, player: .black))
        bank.append(DailyPuzzle(
            id: "open-four-h", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 7, col: 4), (row: 7, col: 9)], reward: 50
        ))

        // 5: Broken four — fill the gap
        stones = []
        stones.append(PlacedStone(row: 7, col: 4, player: .black))
        stones.append(PlacedStone(row: 7, col: 5, player: .black))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        stones.append(PlacedStone(row: 7, col: 8, player: .black))
        bank.append(DailyPuzzle(
            id: "broken-four-h", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 7, col: 6)], reward: 50
        ))

        // 6: Anti-diagonal four blocked SE
        stones = []
        stones.append(PlacedStone(row: 11, col: 3, player: .white))
        stones.append(PlacedStone(row: 10, col: 4, player: .black))
        stones.append(PlacedStone(row: 9, col: 5, player: .black))
        stones.append(PlacedStone(row: 8, col: 6, player: .black))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        bank.append(DailyPuzzle(
            id: "antidiag-block-se", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 6, col: 8)], reward: 50
        ))

        // 7: Broken vertical
        stones = []
        stones.append(PlacedStone(row: 4, col: 7, player: .black))
        stones.append(PlacedStone(row: 5, col: 7, player: .black))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        stones.append(PlacedStone(row: 8, col: 7, player: .black))
        bank.append(DailyPuzzle(
            id: "broken-v", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 6, col: 7)], reward: 50
        ))

        // 8: Open four diagonal
        stones = []
        stones.append(PlacedStone(row: 4, col: 4, player: .black))
        stones.append(PlacedStone(row: 5, col: 5, player: .black))
        stones.append(PlacedStone(row: 6, col: 6, player: .black))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        bank.append(DailyPuzzle(
            id: "open-four-diag", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 3, col: 3), (row: 8, col: 8)], reward: 50
        ))

        // 9: Broken middle diagonal
        stones = []
        stones.append(PlacedStone(row: 4, col: 4, player: .black))
        stones.append(PlacedStone(row: 5, col: 5, player: .black))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        stones.append(PlacedStone(row: 8, col: 8, player: .black))
        bank.append(DailyPuzzle(
            id: "broken-diag", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 6, col: 6)], reward: 50
        ))

        // 10: Horizontal four blocked west
        stones = []
        stones.append(PlacedStone(row: 7, col: 8, player: .white))
        stones.append(PlacedStone(row: 7, col: 4, player: .black))
        stones.append(PlacedStone(row: 7, col: 5, player: .black))
        stones.append(PlacedStone(row: 7, col: 6, player: .black))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        bank.append(DailyPuzzle(
            id: "h-block-west", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 7, col: 3)], reward: 50
        ))

        // 11: Broken four with decoys
        stones = []
        stones.append(PlacedStone(row: 6, col: 5, player: .white))
        stones.append(PlacedStone(row: 6, col: 8, player: .white))
        stones.append(PlacedStone(row: 7, col: 4, player: .black))
        stones.append(PlacedStone(row: 7, col: 5, player: .black))
        stones.append(PlacedStone(row: 7, col: 6, player: .black))
        stones.append(PlacedStone(row: 7, col: 8, player: .black))
        bank.append(DailyPuzzle(
            id: "broken-four-mix", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 7, col: 7)], reward: 50
        ))

        // 12: Diagonal blocked SE
        stones = []
        stones.append(PlacedStone(row: 11, col: 11, player: .white))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        stones.append(PlacedStone(row: 8, col: 8, player: .black))
        stones.append(PlacedStone(row: 9, col: 9, player: .black))
        stones.append(PlacedStone(row: 10, col: 10, player: .black))
        bank.append(DailyPuzzle(
            id: "diag-block-se", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 6, col: 6)], reward: 50
        ))

        // 13: Vertical four blocked bottom
        stones = []
        stones.append(PlacedStone(row: 11, col: 7, player: .white))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        stones.append(PlacedStone(row: 8, col: 7, player: .black))
        stones.append(PlacedStone(row: 9, col: 7, player: .black))
        stones.append(PlacedStone(row: 10, col: 7, player: .black))
        bank.append(DailyPuzzle(
            id: "v-block-bottom", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 6, col: 7)], reward: 50
        ))

        // 14: Anti-diagonal open four
        stones = []
        stones.append(PlacedStone(row: 10, col: 4, player: .black))
        stones.append(PlacedStone(row: 9, col: 5, player: .black))
        stones.append(PlacedStone(row: 8, col: 6, player: .black))
        stones.append(PlacedStone(row: 7, col: 7, player: .black))
        bank.append(DailyPuzzle(
            id: "open-antidiag", title: "Black to win",
            stones: stones, playerToMove: .black,
            winningMoves: [(row: 11, col: 3), (row: 6, col: 8)], reward: 50
        ))

        return bank
    }
}
