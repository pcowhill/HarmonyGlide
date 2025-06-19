//
//  GameScene.swift
//  Test001
//
//  Created by Patrick Cowhill on 4/18/25.
//

import SpriteKit
import GameplayKit

class GameScenePrototype: SKScene {
  
  private var spinnyNode : SKShapeNode?
  private var goalNode : SKShapeNode?
  private var spinnyNodeSelected : Bool?
  private var spinnyNodeWidth : CGFloat?
  private var level : Int?
  
  override func didMove(to view: SKView) {
    
    self.level = 1
    
    // Create shape node to use during mouse interaction
    self.spinnyNodeWidth = (self.size.width + self.size.height) * 0.05
    if let w = self.spinnyNodeWidth {
      self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
    }
    self.spinnyNodeSelected = false
    
    if let spinnyNode = self.spinnyNode {
      spinnyNode.lineWidth = 2.5
      spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
      spinnyNode.position = CGPoint(x:0, y:0)
      spinnyNode.strokeColor = SKColor.white
      spinnyNode.fillColor = SKColor.red
      self.addChild(spinnyNode)
    }
    
    if let w = self.spinnyNodeWidth {
      self.goalNode = SKShapeNode.init(circleOfRadius: w)
      
      if let goalNode = self.goalNode {
        goalNode.lineWidth = 2.5
        goalNode.position = CGPoint(x:2.5*w, y:2.5*w)
        goalNode.strokeColor = SKColor.red
        self.addChild(goalNode)
        
        if let level = self.level {
          createConcentricGoals(parent: goalNode, radius: w - 5.0, depth: level)
        }
      }
    }
  }
  
  
  func createConcentricGoals(parent: SKShapeNode, radius: CGFloat, depth: Int) {
    guard depth > 0 else { return }
    
    let childCircle = SKShapeNode(circleOfRadius: radius)
    childCircle.lineWidth = 2.5
    childCircle.strokeColor = SKColor.red
    childCircle.position = CGPoint.zero
    parent.addChild(childCircle)
    
    createConcentricGoals(parent: childCircle, radius: radius - 5.0, depth: depth - 1)
  }
  
  
  func removeYoungestChild(parent: SKShapeNode) {
    if parent.children.count > 0 {
      if let child = parent.children[0] as? SKShapeNode {
        removeYoungestChild(parent: child)
      }
    } else {
      parent.removeFromParent()
    }
  }
  
  
  func touchDown(atPoint pos : CGPoint) {
    let dx = pos.x - self.spinnyNode!.position.x
    let dy = pos.y - self.spinnyNode!.position.y
    let distance = sqrt(dx * dx + dy * dy)
    
    if let w = self.spinnyNodeWidth {
      if distance < w / sqrt(2) {
        self.spinnyNodeSelected = true
      }
    }
  }
  
  func touchMoved(toPoint pos : CGPoint) {
    if self.spinnyNodeSelected ?? false {
      let dx = pos.x - self.spinnyNode!.position.x
      let dy = pos.y - self.spinnyNode!.position.y
      let distance = sqrt(dx * dx + dy * dy)
      if let w = self.spinnyNodeWidth {
        if distance < 0.75*w {
          self.spinnyNode!.position = pos
        }
      }
    }
  }
  
  func touchUp(atPoint pos : CGPoint) {
    self.spinnyNodeSelected = false
    var dx = self.spinnyNode!.position.x - self.goalNode!.position.x
    var dy = self.spinnyNode!.position.y - self.goalNode!.position.y
    var distance = sqrt(dx * dx + dy * dy)
    var randomFloat1 : CGFloat?
    var randomFloat2 : CGFloat?
    
    if let w = self.spinnyNodeWidth {
      if distance < w {
        print("You score a point!")
        if let goalNode = self.goalNode {
          removeYoungestChild(parent: goalNode)
        }
      }
      if !self.children.contains(self.goalNode!) {
        if let goalNode = self.goalNode {
          self.addChild(goalNode)
          self.level = (self.level ?? 0) + 1
        if (self.level ?? 1) > 9 {
            self.level = 1
          }
          if let level = self.level {
            createConcentricGoals(parent: goalNode, radius: w - 5.0, depth: level)
          }
        }
      }
      while distance < w*1.5 {
        randomFloat1 = CGFloat.random(in: 0.0...1.0)
        randomFloat2 = CGFloat.random(in: 0.0...1.0)
        if let randomFloat1 = randomFloat1, let randomFloat2 = randomFloat2 {
          self.goalNode?.position = CGPoint(x:((randomFloat1 * 5.0) - 2.5) * w, y:((randomFloat2 * 5.0) - 2.5) * w)
          dx = self.spinnyNode!.position.x - self.goalNode!.position.x
          dy = self.spinnyNode!.position.y - self.goalNode!.position.y
          distance = sqrt(dx * dx + dy * dy)
        }
      }
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchDown(atPoint: t.location(in: self)) }
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchUp(atPoint: t.location(in: self)) }
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchUp(atPoint: t.location(in: self)) }
  }
  
  
  override func update(_ currentTime: TimeInterval) {
    // Called before each frame is rendered
  }
}
