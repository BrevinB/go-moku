//
//  TurnBasedMatchManager.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import GameKit
import Foundation

// MARK: - Match Data Model
struct MatchData: Codable {
    var moves: [EncodedMove]
    var boardSize: Int
    var currentPlayerIndex: Int // 0 or 1, refers to participants array order
    var gameStatus: MatchGameStatus

    init(boardSize: Int = 15) {
        self.moves = []
        self.boardSize = boardSize
        self.currentPlayerIndex = 0
        self.gameStatus = .playing
    }

    struct EncodedMove: Codable {
        let row: Int
        let col: Int
        let playerIndex: Int // 0 = first player (black), 1 = second player (white)
    }

    enum MatchGameStatus: String, Codable {
        case playing
        case won
        case draw
    }
}

// MARK: - Turn-Based Match Manager
class TurnBasedMatchManager {
    static let shared = TurnBasedMatchManager()

    private(set) var currentMatch: GKTurnBasedMatch?
    private(set) var matchData: MatchData?

    var isMyTurn: Bool {
        guard let match = currentMatch else { return false }
        return match.currentParticipant?.player == GKLocalPlayer.local
    }

    var localPlayerColor: Player {
        guard let match = currentMatch else { return .black }
        let localIndex = match.participants.firstIndex { $0.player == GKLocalPlayer.local } ?? 0
        return localIndex == 0 ? .black : .white
    }

    var opponentName: String {
        guard let match = currentMatch else { return "Opponent" }
        let opponent = match.participants.first { $0.player != GKLocalPlayer.local }
        return opponent?.player?.displayName ?? "Opponent"
    }

    private init() {
        // Listen for turn notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTurnReceived(_:)),
            name: .gameCenterTurnReceived,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMatchEnded(_:)),
            name: .gameCenterMatchEnded,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Match Data Encoding/Decoding

    func encodeMatchData(_ data: MatchData) -> Data? {
        do {
            return try JSONEncoder().encode(data)
        } catch {
            print("TurnBasedMatchManager: Failed to encode match data - \(error.localizedDescription)")
            return nil
        }
    }

    func decodeMatchData(from data: Data?) -> MatchData? {
        guard let data = data, !data.isEmpty else { return nil }
        do {
            return try JSONDecoder().decode(MatchData.self, from: data)
        } catch {
            print("TurnBasedMatchManager: Failed to decode match data - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Match Management

    func setCurrentMatch(_ match: GKTurnBasedMatch) {
        currentMatch = match
        matchData = decodeMatchData(from: match.matchData) ?? MatchData()
    }

    func clearCurrentMatch() {
        currentMatch = nil
        matchData = nil
    }

    // MARK: - Game Actions

    func makeMove(row: Int, col: Int, completion: @escaping (Bool, Error?) -> Void) {
        guard let match = currentMatch,
              var data = matchData,
              isMyTurn else {
            completion(false, NSError(domain: "TurnBasedMatch", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not your turn"]))
            return
        }

        // Determine player index (0 = first participant/black, 1 = second/white)
        let localIndex = match.participants.firstIndex { $0.player == GKLocalPlayer.local } ?? 0

        // Add the move
        let move = MatchData.EncodedMove(row: row, col: col, playerIndex: localIndex)
        data.moves.append(move)
        data.currentPlayerIndex = localIndex == 0 ? 1 : 0

        matchData = data

        // Encode and send
        guard let encodedData = encodeMatchData(data) else {
            completion(false, NSError(domain: "TurnBasedMatch", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode match data"]))
            return
        }

        // Get next participant
        let nextParticipants = match.participants.filter { $0.player != GKLocalPlayer.local }

        match.endTurn(
            withNextParticipants: nextParticipants,
            turnTimeout: GKTurnTimeoutDefault,
            match: encodedData
        ) { error in
            completion(error == nil, error)
        }
    }

    func endMatchWithWin(completion: @escaping (Error?) -> Void) {
        guard let match = currentMatch,
              var data = matchData else {
            completion(NSError(domain: "TurnBasedMatch", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active match"]))
            return
        }

        data.gameStatus = .won
        matchData = data

        guard let encodedData = encodeMatchData(data) else {
            completion(NSError(domain: "TurnBasedMatch", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode match data"]))
            return
        }

        // Set outcomes - check that participants have valid players
        for participant in match.participants {
            if participant.player == GKLocalPlayer.local {
                participant.matchOutcome = .won
            } else if participant.player != nil {
                participant.matchOutcome = .lost
            } else {
                // Participant hasn't joined yet - they quit by default
                participant.matchOutcome = .quit
            }
        }

        match.endMatchInTurn(withMatch: encodedData) { error in
            completion(error)
        }
    }

    func endMatchWithLoss(completion: @escaping (Error?) -> Void) {
        guard let match = currentMatch,
              var data = matchData else {
            completion(NSError(domain: "TurnBasedMatch", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active match"]))
            return
        }

        data.gameStatus = .won
        matchData = data

        guard let encodedData = encodeMatchData(data) else {
            completion(NSError(domain: "TurnBasedMatch", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode match data"]))
            return
        }

        // Set outcomes (opponent won) - check that participants have valid players
        for participant in match.participants {
            if participant.player == GKLocalPlayer.local {
                participant.matchOutcome = .lost
            } else if participant.player != nil {
                participant.matchOutcome = .won
            } else {
                // Participant hasn't joined yet - they quit by default
                participant.matchOutcome = .quit
            }
        }

        match.endMatchInTurn(withMatch: encodedData) { error in
            completion(error)
        }
    }

    func endMatchWithDraw(completion: @escaping (Error?) -> Void) {
        guard let match = currentMatch,
              var data = matchData else {
            completion(NSError(domain: "TurnBasedMatch", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active match"]))
            return
        }

        data.gameStatus = .draw
        matchData = data

        guard let encodedData = encodeMatchData(data) else {
            completion(NSError(domain: "TurnBasedMatch", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode match data"]))
            return
        }

        // Set outcomes - check that participants have valid players
        for participant in match.participants {
            if participant.player != nil {
                participant.matchOutcome = .tied
            } else {
                // Participant hasn't joined yet - they quit by default
                participant.matchOutcome = .quit
            }
        }

        match.endMatchInTurn(withMatch: encodedData) { error in
            completion(error)
        }
    }

    func resignMatch(completion: @escaping (Error?) -> Void) {
        guard let match = currentMatch else {
            completion(NSError(domain: "TurnBasedMatch", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active match"]))
            return
        }

        if isMyTurn {
            // If it's our turn, quit in turn
            let nextParticipants = match.participants.filter { $0.player != GKLocalPlayer.local }
            match.participantQuitInTurn(
                with: .quit,
                nextParticipants: nextParticipants,
                turnTimeout: GKTurnTimeoutDefault,
                match: match.matchData ?? Data()
            ) { error in
                completion(error)
            }
        } else {
            // If it's not our turn, quit out of turn
            match.participantQuitOutOfTurn(with: .quit) { error in
                completion(error)
            }
        }
    }

    // MARK: - Board State Reconstruction

    func reconstructBoard() -> GomokuBoard {
        let board = GomokuBoard(size: matchData?.boardSize ?? 15)

        guard let data = matchData else { return board }

        for move in data.moves {
            // Temporarily set current player based on move
            board.currentPlayer = move.playerIndex == 0 ? .black : .white
            _ = board.placeStone(at: move.row, col: move.col)
        }

        return board
    }

    // MARK: - Notification Handlers

    @objc private func handleTurnReceived(_ notification: Notification) {
        guard let match = notification.object as? GKTurnBasedMatch else { return }

        // Update current match if it's the same one
        if currentMatch?.matchID == match.matchID {
            setCurrentMatch(match)
        }

        // Post a more specific notification for the UI to handle
        NotificationCenter.default.post(name: .onlineGameTurnUpdated, object: match)
    }

    @objc private func handleMatchEnded(_ notification: Notification) {
        guard let match = notification.object as? GKTurnBasedMatch else { return }

        if currentMatch?.matchID == match.matchID {
            setCurrentMatch(match)
        }

        NotificationCenter.default.post(name: .onlineGameMatchEnded, object: match)
    }
}

// MARK: - Custom Notification Names
extension Notification.Name {
    static let onlineGameTurnUpdated = Notification.Name("onlineGameTurnUpdated")
    static let onlineGameMatchEnded = Notification.Name("onlineGameMatchEnded")
}
