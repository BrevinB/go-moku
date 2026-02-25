//
//  GameViewController.swift
//  Gomoku
//
//  Created by Brevin Blalock on 10/13/25.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.view as! SKView? {
            // Create the menu scene programmatically
            let scene = MenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill

            // Present the scene
            view.presentScene(scene)

            view.ignoresSiblingOrder = true

            view.showsFPS = false
            view.showsNodeCount = false
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
