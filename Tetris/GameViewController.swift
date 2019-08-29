//
//  GameViewController.swift
//  Tetris
//
//  Created by Jie Wu on 2019/08/27.
//  Copyright © 2019 Lindelin. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController, TetrisDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var aButton: UIButton!
    @IBOutlet weak var bButton: UIButton!
    
    var scene: GameScene!
    var tetris: Tetris!
    var panPointReference: CGPoint?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        aButton.layer.cornerRadius = 50
        bButton.layer.cornerRadius = 50
        
        // Configure the view.
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        
        scene.tick = didTick
        
        tetris = Tetris()
        tetris.delegate = self
        tetris.beginGame()
        
        // Present the scene.
        skView.presentScene(scene)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func didTick() {
        tetris.letShapeFall()
    }
    
    func nextShape() {
        let newShapes = tetris.newShape()
        guard let fallingShape = newShapes.fallingShape else {
            return
        }
        self.scene.addPreviewShapeToScene(shape: newShapes.nextShape!) {}
        self.scene.movePreviewShape(shape: fallingShape) {
            // #16
            self.view.isUserInteractionEnabled = true
            self.scene.startTicking()
        }
    }
    
    func gameDidBegin(tetris: Tetris) {
        
        levelLabel.text = "\(tetris.level)"
        scoreLabel.text = "\(tetris.score)"
        
        scene.tickLengthMillis = TickLengthLevelOne
        
        // The following is false when restarting a new game
        if tetris.nextShape != nil && tetris.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(shape: tetris.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }
    
    func gameDidEnd(tetris: Tetris) {
        view.isUserInteractionEnabled = false
        scene.stopTicking()
        
        scene.playSound(sound: "gameover.mp3")
        scene.animateCollapsingLines(linesToRemove: tetris.removeAllBlocks(), fallenBlocks: tetris.removeAllBlocks()) {
            tetris.beginGame()
        }
    }
    
    func gameDidLevelUp(tetris: Tetris) {
        levelLabel.text = "\(tetris.level)"
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        scene.playSound(sound: "levelup.mp3")
    }
    
    func gameShapeDidDrop(tetris: Tetris) {
        scene.stopTicking()
        scene.redrawShape(shape: tetris.fallingShape!) {
            tetris.letShapeFall()
        }
        
        scene.playSound(sound: "drop.mp3")
    }
    
    func gameShapeDidLand(tetris: Tetris) {
        scene.stopTicking()
        
        self.view.isUserInteractionEnabled = false
        
        let removedLines = tetris.removeCompletedLines()
        if removedLines.linesRemoved.count > 0 {
            self.scoreLabel.text = "\(tetris.score)"
            scene.animateCollapsingLines(linesToRemove: removedLines.linesRemoved, fallenBlocks:removedLines.fallenBlocks) {
                
                self.gameShapeDidLand(tetris: tetris)
            }
            scene.playSound(sound: "bomb.mp3")
        } else {
            nextShape()
        }
    }
    
    // #17
    func gameShapeDidMove(tetris: Tetris) {
        scene.redrawShape(shape: tetris.fallingShape!) {}
    }
    
    @IBAction func bButtonTapped(_ sender: Any) {
        tetris.rotateShape()
    }
    
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        let currentPoint = sender.translation(in: self.view)
        
        if let originalPoint = panPointReference {
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9) {
                if sender.velocity(in: self.view).x > CGFloat(0) {
                    tetris.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    tetris.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .began {
            panPointReference = currentPoint
        }
    }
    
    @IBAction func aButtonTapped(_ sender: Any) {
        tetris.dropShape()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UISwipeGestureRecognizer {
            if otherGestureRecognizer is UIPanGestureRecognizer {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            if otherGestureRecognizer is UITapGestureRecognizer {
                return true
            }
        }
        return false
    }
}
