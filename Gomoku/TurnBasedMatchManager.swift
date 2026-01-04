//
//  TurnBasedMatchManager.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import GameKit
import Foundation

// MARK: - Match Error Types
enum MatchError: Error, LocalizedError {
    case notYourTurn
    case noActiveMatch
    case encodingFailed
    case decodingFailed
    case networkUnavailable
    case matchExpired
    case matchInvalid
    case opponentQuit
    case timeout
    case serverError(underlying: Error)
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notYourTurn:
            return "It's not your turn"
        case .noActiveMatch:
            return "No active match found"
        case .encodingFailed:
            return "Failed to save game state"
        case .decodingFailed:
            return "Failed to load game state"
        case .networkUnavailable:
            return "No internet connection"
        case .matchExpired:
            return "This match has expired"
        case .matchInvalid:
            return "This match is no longer valid"
        case .opponentQuit:
            return "Your opponent has left the match"
        case .timeout:
            return "Request timed out"
        case .serverError(let error):
            return "Server error: \(error.localizedDescription)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .serverError:
            return true
        default:
            return false
        }
    }

    static func from(_ error: Error) -> MatchError {
        let nsError = error as NSError

        // Check for specific Game Center error codes
        switch nsError.code {
        case GKError.notAuthenticated.rawValue:
            return .networkUnavailable
        case GKError.communicationsFailure.rawValue:
            return .networkUnavailable
        case GKError.invalidPlayer.rawValue:
            return .opponentQuit
        case GKError.matchNotConnected.rawValue:
            return .networkUnavailable
        case GKError.connectionTimeout.rawValue:
            return .timeout
        default:
            if nsError.domain == NSURLErrorDomain {
                return .networkUnavailable
            }
            return .serverError(underlying: error)
        }
    }
}

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

// MARK: - Retry Configuration
struct RetryConfig {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let backoffMultiplier: Double

    static let `default` = RetryConfig(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        backoffMultiplier: 2.0
    )

    func delay(for attempt: Int) -> TimeInterval {
        let delay = initialDelay * pow(backoffMultiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

// MARK: - Turn-Based Match Manager
class TurnBasedMatchManager {
    static let shared = TurnBasedMatchManager()

    private(set) var currentMatch: GKTurnBasedMatch?
    private(set) var matchData: MatchData?

    // Retry configuration
    private let retryConfig = RetryConfig.default

    // Track pending operations for retry
    private var pendingMoveData: (row: Int, col: Int, originalData: MatchData)?

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

    /// Returns the current match status
    var matchStatus: MatchStatus {
        guard let match = currentMatch else { return .noMatch }

        switch match.status {
        case .open:
            // Check if opponent quit
            let opponent = match.participants.first { $0.player != GKLocalPlayer.local }
            if opponent?.matchOutcome == .quit {
                return .opponentQuit
            }
            return .active
        case .ended:
            return .ended
        case .matching:
            return .waitingForOpponent
        case .unknown:
            return .invalid
        @unknown default:
            return .invalid
        }
    }

    enum MatchStatus {
        case noMatch
        case waitingForOpponent
        case active
        case ended
        case opponentQuit
        case invalid
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

    func makeMove(row: Int, col: Int, completion: @escaping (Bool, MatchError?) -> Void) {
        // Check network connectivity first
        guard NetworkMonitor.shared.isConnected else {
            completion(false, .networkUnavailable)
            return
        }

        guard let match = currentMatch,
              var data = matchData,
              isMyTurn else {
            completion(false, .notYourTurn)
            return
        }

        // Store original data for rollback
        let originalData = data

        // Determine player index (0 = first participant/black, 1 = second/white)
        let localIndex = match.participants.firstIndex { $0.player == GKLocalPlayer.local } ?? 0

        // Add the move
        let move = MatchData.EncodedMove(row: row, col: col, playerIndex: localIndex)
        data.moves.append(move)
        data.currentPlayerIndex = localIndex == 0 ? 1 : 0

        matchData = data
        pendingMoveData = (row, col, originalData)

        // Encode and send
        guard let encodedData = encodeMatchData(data) else {
            matchData = originalData
            pendingMoveData = nil
            completion(false, .encodingFailed)
            return
        }

        // Get next participant
        let nextParticipants = match.participants.filter { $0.player != GKLocalPlayer.local }

        // Execute with retry
        executeMoveWithRetry(
            match: match,
            nextParticipants: nextParticipants,
            encodedData: encodedData,
            originalData: originalData,
            attempt: 1,
            completion: completion
        )
    }

    private func executeMoveWithRetry(
        match: GKTurnBasedMatch,
        nextParticipants: [GKTurnBasedParticipant],
        encodedData: Data,
        originalData: MatchData,
        attempt: Int,
        completion: @escaping (Bool, MatchError?) -> Void
    ) {
        match.endTurn(
            withNextParticipants: nextParticipants,
            turnTimeout: GKTurnTimeoutDefault,
            match: encodedData
        ) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                let matchError = MatchError.from(error)

                // Check if we should retry
                if matchError.isRetryable && attempt < self.retryConfig.maxAttempts {
                    let delay = self.retryConfig.delay(for: attempt)
                    print("TurnBasedMatchManager: Retry attempt \(attempt + 1) after \(delay)s")

                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.executeMoveWithRetry(
                            match: match,
                            nextParticipants: nextParticipants,
                            encodedData: encodedData,
                            originalData: originalData,
                            attempt: attempt + 1,
                            completion: completion
                        )
                    }
                } else {
                    // Rollback on final failure
                    self.matchData = originalData
                    self.pendingMoveData = nil
                    completion(false, matchError)
                }
            } else {
                self.pendingMoveData = nil
                completion(true, nil)
            }
        }
    }

    /// Retry the last failed move if one exists
    func retryPendingMove(completion: @escaping (Bool, MatchError?) -> Void) {
        guard let pending = pendingMoveData else {
            completion(false, .noActiveMatch)
            return
        }

        // Restore original state and try again
        matchData = pending.originalData
        makeMove(row: pending.row, col: pending.col, completion: completion)
    }

    /// Check if there's a pending move that can be retried
    var hasPendingMove: Bool {
        return pendingMoveData != nil
    }

    /// Clear any pending move data
    func clearPendingMove() {
        pendingMoveData = nil
    }

    func endMatchWithWin(completion: @escaping (MatchError?) -> Void) {
        guard NetworkMonitor.shared.isConnected else {
            completion(.networkUnavailable)
            return
        }

        guard let match = currentMatch,
              var data = matchData else {
            completion(.noActiveMatch)
            return
        }

        data.gameStatus = .won
        matchData = data

        guard let encodedData = encodeMatchData(data) else {
            completion(.encodingFailed)
            return
        }

        // Set outcomes - check that participants have valid players
        for participant in match.participants {
            if participant.player == GKLocalPlayer.local {
                participant.matchOutcome = .won
            } else if participant.player != nil {
                participant.matchOutcome = .lost
            } else {
                participant.matchOutcome = .quit
            }
        }

        match.endMatchInTurn(withMatch: encodedData) { error in
            if let error = error {
                completion(MatchError.from(error))
            } else {
                completion(nil)
            }
        }
    }

    func endMatchWithLoss(completion: @escaping (MatchError?) -> Void) {
        guard NetworkMonitor.shared.isConnected else {
            completion(.networkUnavailable)
            return
        }

        guard let match = currentMatch,
              var data = matchData else {
            completion(.noActiveMatch)
            return
        }

        data.gameStatus = .won
        matchData = data

        guard let encodedData = encodeMatchData(data) else {
            completion(.encodingFailed)
            return
        }

        // Set outcomes (opponent won)
        for participant in match.participants {
            if participant.player == GKLocalPlayer.local {
                participant.matchOutcome = .lost
            } else if participant.player != nil {
                participant.matchOutcome = .won
            } else {
                participant.matchOutcome = .quit
            }
        }

        match.endMatchInTurn(withMatch: encodedData) { error in
            if let error = error {
                completion(MatchError.from(error))
            } else {
                completion(nil)
            }
        }
    }

    func endMatchWithDraw(completion: @escaping (MatchError?) -> Void) {
        guard NetworkMonitor.shared.isConnected else {
            completion(.networkUnavailable)
            return
        }

        guard let match = currentMatch,
              var data = matchData else {
            completion(.noActiveMatch)
            return
        }

        data.gameStatus = .draw
        matchData = data

        guard let encodedData = encodeMatchData(data) else {
            completion(.encodingFailed)
            return
        }

        for participant in match.participants {
            if participant.player != nil {
                participant.matchOutcome = .tied
            } else {
                participant.matchOutcome = .quit
            }
        }

        match.endMatchInTurn(withMatch: encodedData) { error in
            if let error = error {
                completion(MatchError.from(error))
            } else {
                completion(nil)
            }
        }
    }

    func resignMatch(completion: @escaping (MatchError?) -> Void) {
        guard NetworkMonitor.shared.isConnected else {
            completion(.networkUnavailable)
            return
        }

        guard let match = currentMatch else {
            completion(.noActiveMatch)
            return
        }

        if isMyTurn {
            let nextParticipants = match.participants.filter { $0.player != GKLocalPlayer.local }
            match.participantQuitInTurn(
                with: .quit,
                nextParticipants: nextParticipants,
                turnTimeout: GKTurnTimeoutDefault,
                match: match.matchData ?? Data()
            ) { error in
                if let error = error {
                    completion(MatchError.from(error))
                } else {
                    completion(nil)
                }
            }
        } else {
            match.participantQuitOutOfTurn(with: .quit) { error in
                if let error = error {
                    completion(MatchError.from(error))
                } else {
                    completion(nil)
                }
            }
        }
    }

    // MARK: - Match Validation

    /// Validates the current match state and returns any issues
    func validateMatch() -> MatchError? {
        guard let match = currentMatch else {
            return .noActiveMatch
        }

        // Check match status
        switch match.status {
        case .ended:
            return .matchExpired
        case .unknown:
            return .matchInvalid
        default:
            break
        }

        // Check if opponent quit
        let opponent = match.participants.first { $0.player != GKLocalPlayer.local }
        if opponent?.matchOutcome == .quit {
            return .opponentQuit
        }

        // Check data integrity
        if match.matchData != nil && matchData == nil {
            return .decodingFailed
        }

        return nil
    }

    /// Reload match data from server
    func refreshMatch(completion: @escaping (MatchError?) -> Void) {
        guard NetworkMonitor.shared.isConnected else {
            completion(.networkUnavailable)
            return
        }

        guard let matchID = currentMatch?.matchID else {
            completion(.noActiveMatch)
            return
        }

        GKTurnBasedMatch.load(withID: matchID) { [weak self] match, error in
            if let error = error {
                completion(MatchError.from(error))
                return
            }

            guard let match = match else {
                completion(.matchInvalid)
                return
            }

            self?.setCurrentMatch(match)
            completion(nil)
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
