//
//  PuzzleManager.swift
//  Gomoku
//

import Foundation

class PuzzleManager {
    static let shared = PuzzleManager()

    private let lastSolvedDateKey = "puzzleLastSolvedDate"
    private let lastSolvedIdKey = "puzzleLastSolvedId"

    private init() {}

    var todaysPuzzle: DailyPuzzle {
        DailyPuzzle.todaysPuzzle()
    }

    var hasSolvedToday: Bool {
        guard let date = UserDefaults.standard.object(forKey: lastSolvedDateKey) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(date)
    }

    @discardableResult
    func markSolved() -> Int {
        let puzzle = todaysPuzzle
        guard !hasSolvedToday else { return 0 }
        UserDefaults.standard.set(Date(), forKey: lastSolvedDateKey)
        UserDefaults.standard.set(puzzle.id, forKey: lastSolvedIdKey)
        CoinManager.shared.addCoins(puzzle.reward)
        return puzzle.reward
    }
}
