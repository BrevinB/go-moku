//
//  GameStateMachine.swift
//  Gomoku
//
//  GKStateMachine-based game flow controller. Manages transitions between
//  waiting for human input, AI thinking, and game-over states.
//

import GameplayKit
import SpriteKit

// MARK: - Game Flow Context

/// Shared context that every state uses to communicate back to the scene.
class GameFlowContext {
    weak var scene: GameScene?

    init(scene: GameScene) {
        self.scene = scene
    }
}

// MARK: - WaitingForInput

/// Human player's turn — touch input is accepted.
class WaitingForInputState: GKState {
    let context: GameFlowContext

    init(context: GameFlowContext) {
        self.context = context
        super.init()
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is AIThinkingState.Type ||
               stateClass is GameOverState.Type
    }

    override func didEnter(from previousState: GKState?) {
        context.scene?.onEnterWaitingForInput()
    }
}

// MARK: - AIThinking

/// AI is computing its move — touch input is blocked, thinking indicator is shown.
class AIThinkingState: GKState {
    let context: GameFlowContext

    init(context: GameFlowContext) {
        self.context = context
        super.init()
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is WaitingForInputState.Type ||
               stateClass is GameOverState.Type
    }

    override func didEnter(from previousState: GKState?) {
        context.scene?.onEnterAIThinking()
    }

    override func willExit(to nextState: GKState) {
        context.scene?.onExitAIThinking()
    }
}

// MARK: - GameOver

/// Terminal state — the game has been won or drawn.
class GameOverState: GKState {
    let context: GameFlowContext

    init(context: GameFlowContext) {
        self.context = context
        super.init()
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        // A reset can bring us back to waiting
        return stateClass is WaitingForInputState.Type
    }

    override func didEnter(from previousState: GKState?) {
        context.scene?.onEnterGameOver()
    }
}

// MARK: - Factory

extension GKStateMachine {
    /// Build the Gomoku game-flow state machine.
    static func gomokuStateMachine(context: GameFlowContext) -> GKStateMachine {
        let waiting  = WaitingForInputState(context: context)
        let thinking = AIThinkingState(context: context)
        let gameOver = GameOverState(context: context)
        return GKStateMachine(states: [waiting, thinking, gameOver])
    }
}
