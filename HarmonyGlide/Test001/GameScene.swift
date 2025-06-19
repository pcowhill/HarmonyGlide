//
//  GameScene.swift
//  Test001
//
//  Created by Patrick Cowhill on 4/18/25.
//

import SpriteKit
import GameplayKit

// ###############################################################################
// Helper Classes
// ###############################################################################

enum NodeType {
  case square, goal, tracker, menuEntry, description
}

enum GameMode {
  case menu, play
}

enum Movement {
  case dvd, orbit
}

struct Properties: Hashable {
  var goalDepth : Int?
  var color = SKColor.red
  var movement : Movement?
  var speed = 100.0
  var initPosX : CGFloat?
  var initPosY : CGFloat?
  var labelName : String?
  var labelDone : Bool = false
}

struct NodeData: Hashable {
  let id: UUID = UUID() // Unique identifier to keep notes distinct in set
  var type : NodeType
  var properties : Properties
}

struct StageData {
  var name : String
  var description : String?
  var levels : [Set<NodeData>]
}

struct GameData {
  var stages : [StageData]
}

class PropertyNode : SKShapeNode {
  var properties = Properties()
  var nodeType : NodeType!
  var isSelected : Bool = false
  var goalDepth : Int?
  var velocityX = CGFloat(0.0)
  var velocityY = CGFloat(0.0)
  
  convenience init(type: NodeType, width: CGFloat, properties: Properties) {
    if type == .square {
      self.init(rectOf: CGSize(width: width, height: width), cornerRadius: width * 0.3)
      self.lineWidth = 2.5
      self.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
      self.strokeColor = .white
      self.fillColor = properties.color
    } else if type == .goal {
      self.init(circleOfRadius: width)
      self.lineWidth = 2.5
      self.strokeColor = properties.color
      self.goalDepth = properties.goalDepth ?? 0
    } else if type == .tracker {
      self.init(circleOfRadius: width/6.0)
      self.lineWidth = 2.5
      self.strokeColor = .white
      if let posX = properties.initPosX, let posY = properties.initPosY {
        self.position = CGPoint(x: posX, y: posY)
      }
    } else if type == .menuEntry {
      self.init(rectOf: CGSize(width: width * 3.0, height: width), cornerRadius: width * 0.3)
      self.lineWidth = 2.5
      self.strokeColor = .white
      if let posX = properties.initPosX, let posY = properties.initPosY {
        self.position = CGPoint(x: posX, y: posY)
      }
      if let labelName = properties.labelName {
        let label = SKLabelNode(text: labelName)
        label.fontSize = 32
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 0)
        self.addChild(label)
      }
      if properties.labelDone {
        let label2 = SKLabelNode(text: "✔")
        label2.fontSize = 32
        label2.fontColor = .white
        label2.verticalAlignmentMode = .center
        label2.horizontalAlignmentMode = .right
        label2.position = CGPoint(x: width * 1.25, y: 0)
        self.addChild(label2)
      }
    } else {
      self.init(rectOf: CGSize(width: width * 7.0, height: width * 8.0))
      if let labelName = properties.labelName {
        self.lineWidth = 0.0
        self.strokeColor = .white
        let description = SKLabelNode(text: labelName)
        description.fontSize = 32
        description.fontColor = .white
        description.verticalAlignmentMode = .top
        description.position = CGPoint(x: 0, y: width * 8.0 / 2.0)
        self.addChild(description)
      }
    }
    if let movement = properties.movement {
      if movement == .dvd {
        let rotation = CGFloat.random(in:0.0...1.0)
        self.velocityX = CGFloat(cos(Double.pi * 2 * rotation)) * properties.speed
        self.velocityY = CGFloat(sin(Double.pi * 2 * rotation)) * properties.speed
      }
    }
    self.properties = properties
    self.nodeType = type
  }
}


// ###############################################################################
// Game Scene Class
// ###############################################################################

class GameScene: SKScene {
  
  // ###############################################################################
  // Attributes
  // ###############################################################################
  private var gameMode = GameMode.play
  private var stageId : Int?
  private var levelId : Int?
  private var squareWidth : CGFloat?
  private var previousTime : TimeInterval?
  private var completedStages : Set<Int> = []
  
  // ###############################################################################
  // Game Data
  // ###############################################################################
  private let gameData = GameData(
    stages: [
      StageData(
        name: "Tutorial 1",
        description: "Welcome!  Drag the sqaure to the goal with your finger.",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 0))
        ])]
      ),
      StageData(
        name: "Tutorial 2",
        description: "Some stages have multiple levels to complete.",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 0))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 0))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 0))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 0))
        ])]
      ),
      StageData(
        name: "Tutorial 3",
        description: "Some goals require multiple steps to complete.",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 2))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 4))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 7))
        ])]
      ),
      StageData(
        name: "Tutorial 4",
        description: "Some levels have many squares.",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 1))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 2))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 3))
        ])]
      ),
      StageData(
        name: "Tutorial 5",
        description: "And some levels have many goals!",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 1)),
          NodeData(type: .goal, properties: Properties(goalDepth: 3))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 1)),
          NodeData(type: .goal, properties: Properties(goalDepth: 3)),
          NodeData(type: .goal, properties: Properties(goalDepth: 5))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 1)),
          NodeData(type: .goal, properties: Properties(goalDepth: 3)),
          NodeData(type: .goal, properties: Properties(goalDepth: 5)),
          NodeData(type: .goal, properties: Properties(goalDepth: 7))
        ])]
      ),
      StageData(
        name: "Easy 1",
        description: "Some squares and goals are other colors.",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, color: .blue))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 6, color: .blue))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 3, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 3, color: .blue))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 9, color: .blue))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 1, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 3, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 5, color: .blue))
        ])]
      ),
      StageData(
        name: "Easy 2",
        description: "Use the right color square on the goal.",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, color: .blue))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, color: .blue))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0)),
          NodeData(type: .goal, properties: Properties(goalDepth: 1, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 2)),
          NodeData(type: .goal, properties: Properties(goalDepth: 3, color: .blue))
        ])]
      ),
      StageData(
        name: "Easy 3",
        description: "You are doing great!",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, color: .blue))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .goal, properties: Properties(goalDepth: 0)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .blue))
        ])]
      ),
      StageData(
        name: "Medium 1",
        description: "Let's add even more colors!",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .goal, properties: Properties(goalDepth: 2, color: .orange)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, color: .orange))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 1, color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 3, color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 5, color: .green)),
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 6, color: .green))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 7, color: .orange))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 1, color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 2, color: .orange)),
          NodeData(type: .goal, properties: Properties(goalDepth: 3, color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, color: .orange)),
          NodeData(type: .goal, properties: Properties(goalDepth: 5, color: .green))
        ])]
      ),
      StageData(
        name: "Medium 2",
        description: "Remember to use the right color on the goal.",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 0, color: .orange))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 2))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, color: .green))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 7, color: .blue))
        ])]
      ),
      StageData(
        name: "Medium 3",
        description: "So many colors; so many goals!",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4)),
          NodeData(type: .goal, properties: Properties(goalDepth: 5, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 6, color: .green))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 5, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 6, color: .orange))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 6)),
          NodeData(type: .goal, properties: Properties(goalDepth: 5, color: .orange)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, color: .green))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 7)),
          NodeData(type: .goal, properties: Properties(goalDepth: 7, color: .blue)),
          NodeData(type: .goal, properties: Properties(goalDepth: 7, color: .orange)),
          NodeData(type: .goal, properties: Properties(goalDepth: 7, color: .green))
        ])]
      ),
      StageData(
        name: "Hard",
        description: "Try that again, but with movement!",
        levels: [Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, movement: .dvd)),
          NodeData(type: .goal, properties: Properties(goalDepth: 5, color: .blue, movement: .dvd)),
          NodeData(type: .goal, properties: Properties(goalDepth: 6, color: .green, movement: .dvd))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, color: .blue, movement: .dvd)),
          NodeData(type: .goal, properties: Properties(goalDepth: 5, color: .blue, movement: .dvd)),
          NodeData(type: .goal, properties: Properties(goalDepth: 6, color: .orange, movement: .dvd))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 6, movement: .dvd)),
          NodeData(type: .goal, properties: Properties(goalDepth: 5, color: .orange, movement: .dvd)),
          NodeData(type: .goal, properties: Properties(goalDepth: 4, color: .green, movement: .dvd))
        ]), Set<NodeData>([
          NodeData(type: .square, properties: Properties()),
          NodeData(type: .square, properties: Properties(color: .blue)),
          NodeData(type: .square, properties: Properties(color: .orange)),
          NodeData(type: .square, properties: Properties(color: .green)),
          NodeData(type: .goal, properties: Properties(goalDepth: 7, movement: .dvd)),
          NodeData(type: .goal, properties: Properties(goalDepth: 7, color: .blue, movement: .dvd)),
          NodeData(type: .goal, properties: Properties(goalDepth: 7, color: .orange, movement: .dvd)),
          NodeData(type: .goal, properties: Properties(goalDepth: 7, color: .green, movement: .dvd))
        ])]
      )
    ]
  )
  
  // ###############################################################################
  // Set-up function
  // ###############################################################################
  override func didMove(to view: SKView) {
    self.squareWidth = (self.size.width + self.size.height) * 0.05
    
    startMenu()
    //startCurrentStage()
  }
  
  // ###############################################################################
  // Menu Helpers
  // ###############################################################################
  func startMenu() {
    let numStages = self.gameData.stages.count
    if let width = self.squareWidth {
      let title = PropertyNode(type: .description, width: width, properties: Properties(labelName: "Harmony Glide v1.0"))
      self.addChild(title)
      for i in 0...numStages-1 {
        let spacing = Float(width)
        let nearHalfSpacing = spacing / 2.0 + 10.0
        let numStagesFloat = Float(numStages-1)
        let iFloat = Float(i)
        let initX = CGFloat(pow(-1, Float(i)) * (-1.5 * spacing - 10.0))
        let initY = -CGFloat(nearHalfSpacing * iFloat - nearHalfSpacing * numStagesFloat / 2.0 + 70.0)
        let labelName = self.gameData.stages[i].name
        var labelDone = false
        if self.completedStages.contains(i) {
          labelDone = true
        }
        let properties = Properties(initPosX: initX, initPosY: initY, labelName: labelName, labelDone: labelDone)
        let node = PropertyNode(type: .menuEntry, width: width, properties: properties)
        self.addChild(node)
      }
    }
  }
  
  
  // ###############################################################################
  // Stage and Level helpers
  // ###############################################################################
  func startCurrentStage() {
    if self.stageId == nil {
      self.stageId = 0
    }
    let numLevels = self.gameData.stages[self.stageId!].levels.count
    if let width = self.squareWidth {
      for i in 0...numLevels-1 {
        let spacing = Float(width)
        let numLevelsFloat = Float(numLevels-1)
        let iFloat = Float(i)
        let initX = spacing * iFloat - spacing * numLevelsFloat / 2.0
        let initY = 4.5 * spacing
        let properties = Properties(initPosX: CGFloat(initX), initPosY: CGFloat(initY))
        let node = PropertyNode(type: .tracker, width: width, properties: properties)
        self.addChild(node)
      }
    }
    if let description = self.gameData.stages[self.stageId!].description, let width = self.squareWidth {
      let properties = Properties(labelName: description)
      let node = PropertyNode(type: .description, width: width, properties: properties)
      self.addChild(node)
    }
    startCurrentLevel()
  }
  
  func startCurrentLevel() {
    if self.levelId == nil {
      self.levelId = 0
    }
    if let stageId = self.stageId, let levelId = self.levelId, let width = self.squareWidth {
      let startingNodes = self.gameData.stages[stageId].levels[levelId]
      for nodeData in startingNodes {
        let node = PropertyNode(type: nodeData.type, width: width, properties: nodeData.properties)
        setNewPosition(node: node, minDistance: 1.5*width)
        if node.nodeType == .goal {
          if let goalDepth = node.goalDepth {
            createConcentricGoals(parent: node, radius: width - 5.0, depth: goalDepth, color: node.properties.color)
          }
        }
        self.addChild(node)
      }
    }
  }
  
  func nextLevelIfComplete() {
    let goalChildren = self.children
      .compactMap{ $0 as? PropertyNode }
      .filter { $0.nodeType == .goal }
    if goalChildren.isEmpty {
      updateTracker()
      removeAllSquares() {
        self.levelId! += 1
        if self.levelId! < self.gameData.stages[self.stageId!].levels.count {
          self.startCurrentLevel()
        } else {
          self.removeDescription()
          self.removeAllTrackers()
          self.completedStages.insert(self.stageId!)
          self.levelId = nil
          self.stageId = nil
          self.startMenu()
        }
      }
    }
  }
  
  
  // ###############################################################################
  // Node Helpers
  // ###############################################################################
  func setNewMovement(node: PropertyNode) {
    let properties = node.properties
    if let movement = properties.movement {
      if movement == .dvd {
        let rotation = CGFloat.random(in:0.0...1.0)
        node.velocityX = CGFloat(cos(Double.pi * 2 * rotation)) * properties.speed
        node.velocityY = CGFloat(sin(Double.pi * 2 * rotation)) * properties.speed
      }
    }
  }
  
  func setNewPosition(node: SKShapeNode, minDistance: CGFloat) {
    var distance = 0.0
    var candidatePos = CGPoint(x: 0.0, y: 0.0)
    while distance < minDistance {
      if let w = self.squareWidth {
        let candidateX = CGFloat.random(in:-2.5*w...2.5*w)
        let candidateY = CGFloat.random(in:-3.5*w...3.5*w)
        candidatePos = CGPoint(x: candidateX, y: candidateY)
        if let closestChild = closestNodeToPos(nodes: self.children, pos: candidatePos) {
          distance = nodeToPosDistance(node: closestChild, pos: candidatePos)
        } else {
          distance = minDistance + 1.0
        }
      }
    }
    node.position = candidatePos
  }
  
  func nodeToPosDistance(node: SKNode, pos: CGPoint) -> CGFloat {
    let dx = node.position.x - pos.x;
    let dy = node.position.y - pos.y;
    return sqrt(dx * dx + dy * dy)
  }
  
  func nodeToNodeDistance(node1: SKNode, node2: SKNode) -> CGFloat {
    return nodeToPosDistance(node: node1, pos: node2.position)
  }
  
  func closestNodeToPos(nodes: [SKNode], pos: CGPoint) -> SKNode? {
    guard !nodes.isEmpty else { return nil }
    var minDistance = nodeToPosDistance(node: nodes[0], pos: pos)
    var closestNode: SKNode? = nodes[0]
    for node in nodes {
      let distance = nodeToPosDistance(node: node, pos: pos)
      if distance < minDistance {
        minDistance = distance
        closestNode = node
      }
    }
    return closestNode
  }
  
  
  // ###############################################################################
  // Square Helpers
  // ###############################################################################
  func removeAllSquares(completion: @escaping () -> Void) {
    let squareChildren = self.children
      .compactMap{ $0 as? PropertyNode }
      .filter { $0.nodeType == .square }
    let pause = SKAction.wait(forDuration: 1.0)
    let delay = SKAction.wait(forDuration: 0.1)
    let playFifth = SKAction.playSoundFileNamed("g1.wav", waitForCompletion: false)
    let playRoot = SKAction.playSoundFileNamed("c2.wav", waitForCompletion: false)
    let playThird = SKAction.playSoundFileNamed("e2.wav", waitForCompletion: false)
    let playChord = SKAction.sequence([playFifth, delay, playRoot, delay, playThird])
    let fadeOut = SKAction.fadeOut(withDuration: 1.0)
    let remove = SKAction.removeFromParent()
    let fadeAndRemove = SKAction.sequence([pause, playChord, fadeOut, remove])
    let dispatchGroup = DispatchGroup()
    for squareChild in squareChildren {
      dispatchGroup.enter()
      squareChild.run(fadeAndRemove) {
        dispatchGroup.leave()
      }
    }
    dispatchGroup.notify(queue: .main) {
      completion()
    }
  }
  
  // ###############################################################################
  // Goal Helpers
  // ###############################################################################
  func createConcentricGoals(parent: SKShapeNode, radius: CGFloat, depth: Int, color: SKColor) {
    guard depth > 0 else { return }
    
    let childCircle = SKShapeNode(circleOfRadius: radius)
    childCircle.lineWidth = 2.5
    childCircle.strokeColor = color
    childCircle.position = CGPoint.zero
    parent.addChild(childCircle)
    
    createConcentricGoals(parent: childCircle, radius: radius - 5.0, depth: depth - 1, color: color)
  }
  
  func removeYoungestChild(parent : SKShapeNode) {
    if parent.children.count > 0 {
      if let child = parent.children[0] as? SKShapeNode {
        removeYoungestChild(parent: child)
      }
    } else {
      parent.removeFromParent()
    }
  }
  
  func numberOfGoalsRemaining(goal : SKShapeNode) -> Int {
    if goal.children.count > 0 {
      if let child = goal.children[0] as? SKShapeNode {
        return numberOfGoalsRemaining(goal: child) + 1
      }
    }
    return 1
  }
  
  func playGoalSound(goal: PropertyNode) {
    let orderedSoundFiles = ["c1.wav", "d1.wav", "e1.wav", "f1.wav", "g1.wav", "a2.wav", "b2.wav", "c2.wav", "d2.wav", "e2.wav"]
    let goalsRemaining = numberOfGoalsRemaining(goal: goal)
    let soundToPlay = orderedSoundFiles[goalsRemaining - 1]
    run(SKAction.playSoundFileNamed(soundToPlay, waitForCompletion: false))
  }
  
  func scoreIfGoal(atPoint pos : CGPoint, color: SKColor) {
    let goalChildren = self.children
      .compactMap{ $0 as? PropertyNode }
      .filter { $0.nodeType == .goal }
    if let closestGoal = closestNodeToPos(nodes: goalChildren, pos: pos) as? PropertyNode {
      if let squareWidth = self.squareWidth {
        let distanceToGoal = nodeToPosDistance(node: closestGoal, pos: pos)
        if  distanceToGoal < squareWidth / sqrt(2) && closestGoal.properties.color == color {
          playGoalSound(goal: closestGoal)
          removeYoungestChild(parent: closestGoal)
          setNewPosition(node: closestGoal, minDistance: 1.5*squareWidth)
          setNewMovement(node: closestGoal)
          nextLevelIfComplete()
        }
      }
    }
  }
  
  // ###############################################################################
  // Tracker Helpers
  // ###############################################################################
  func updateTracker() {
    let trackerChildren = self.children
      .compactMap{ $0 as? PropertyNode }
      .filter { $0.nodeType == .tracker }
    if let levelId = self.levelId {
      trackerChildren[levelId].fillColor = .white
    }
  }
  
  func removeAllTrackers() {
    let trackerChildren = self.children
      .compactMap{ $0 as? PropertyNode }
      .filter { $0.nodeType == .tracker }
    for trackerChild in trackerChildren {
      trackerChild.removeFromParent()
    }
  }
  
  // ###############################################################################
  // Description Helpers
  // ###############################################################################
  func removeDescription() {
    let descriptionChildren = self.children
      .compactMap{ $0 as? PropertyNode }
      .filter { $0.nodeType == .description }
    for descriptionChild in descriptionChildren {
      descriptionChild.removeFromParent()
    }
  }
  
  // ###############################################################################
  // Touch Handlers
  // ###############################################################################
  func touchDown(atPoint pos : CGPoint) {
    let squareChildren = self.children
      .compactMap{ $0 as? PropertyNode }
      .filter { $0.nodeType == .square }
      .filter { $0.isSelected == false }
    if let closestSquare = closestNodeToPos(nodes: squareChildren, pos: pos) as? PropertyNode {
      if let squareWidth = self.squareWidth {
        let distanceToSquare = nodeToPosDistance(node: closestSquare, pos: pos)
        if  distanceToSquare < squareWidth / sqrt(2) {
          closestSquare.isSelected = true
          closestSquare.position = pos
        }
      }
    }
    
    let menuEntryChildren = self.children
      .compactMap{ $0 as? PropertyNode }
      .filter { $0.nodeType == .menuEntry }
    if !menuEntryChildren.isEmpty {
      for i in 0...menuEntryChildren.count-1 {
        let menuEntryChild = menuEntryChildren[i]
        if menuEntryChild.contains(pos) {
          self.stageId = i
          self.levelId = 0
          for menuEntryChild2 in menuEntryChildren {
            menuEntryChild2.removeFromParent()
          }
          let descriptionChildren = self.children
            .compactMap{ $0 as? PropertyNode }
            .filter { $0.nodeType == .description }
          for descriptionChild in descriptionChildren {
            descriptionChild.removeFromParent()
          }
          startCurrentStage()
        }
      }
    }
  }
  
  func touchMoved(toPoint pos : CGPoint) {
    let squareChildren = self.children
      .compactMap{ $0 as? PropertyNode }
      .filter { $0.nodeType == .square }
      .filter { $0.isSelected == true }
    if let closestSquare = closestNodeToPos(nodes: squareChildren, pos: pos) as? PropertyNode {
      if let squareWidth = self.squareWidth {
        let distanceToSquare = nodeToPosDistance(node: closestSquare, pos: pos)
        if  distanceToSquare < squareWidth {
          closestSquare.position = pos
        }
      }
    }
  }
  
  func touchUp(atPoint pos : CGPoint) {
    let squareChildren = self.children
      .compactMap{ $0 as? PropertyNode }
      .filter { $0.nodeType == .square }
      .filter { $0.isSelected == true }
    if let closestSquare = closestNodeToPos(nodes: squareChildren, pos: pos) as? PropertyNode {
      if let squareWidth = self.squareWidth {
        let distanceToSquare = nodeToPosDistance(node: closestSquare, pos: pos)
        if distanceToSquare < squareWidth / sqrt(2) {
          closestSquare.isSelected = false
          scoreIfGoal(atPoint: pos, color: closestSquare.properties.color)
        }
      }
    }
  }
  
  
  
  // ###############################################################################
  // Touch Overrides
  // ###############################################################################
  
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
    guard let previousTime = self.previousTime else {
      self.previousTime = currentTime
      return
    }
    let timeDifference = currentTime - previousTime
    let childNodes = self.children
      .compactMap{ $0 as? PropertyNode }
    for childNode in childNodes {
      if let movement = childNode.properties.movement, let width = self.squareWidth {
        if movement == .dvd {
          let pos = childNode.position
          if pos.x > 2.5 * width {
            childNode.velocityX = -abs(childNode.velocityX)
          } else if pos.x < -2.5 * width {
            childNode.velocityX = abs(childNode.velocityX)
          }
          if pos.y > 3.5 * width {
            childNode.velocityY = -abs(childNode.velocityY)
          } else if pos.y < -3.5 * width {
            childNode.velocityY = abs(childNode.velocityY)
          }
          let posXchange = childNode.velocityX * timeDifference
          let posYchange = childNode.velocityY * timeDifference
          childNode.position.x += posXchange
          childNode.position.y += posYchange
        } else if movement == .orbit {
          
        }
      }
    }
    self.previousTime = currentTime
  }
}
