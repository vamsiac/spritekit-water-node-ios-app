//
//  GameScene.swift
//  spritekit-water-node-ios-app
//
//  Created by Astemir Eleev on 24/03/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//

import SpriteKit
import GameplayKit


class GameScene: SKScene {

    // MARK: - Static properties
    
    static var viewportSize: CGSize = .zero
    
    // MARK: - Properties

    let surfaceHeight: CGFloat = 235
    var splashWidth: CGFloat = 20.0
    var splashForceMultiplier: CGFloat = 0.125
    
    let fixedTimeStep: TimeInterval = 1.0 / 500
    
//    var waterNode: WaterNode!
    var waterNode: DynamicWaterNode!
    
    let waterColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.5)
    
    private var clouds: [SKSpriteNode] = []
    private var boxes: [DropNode] = []
    
    private var deltaTime: CFTimeInterval = 0.0
    private var hasReferenceFrameTime: Bool = false
    
    private var updatables: [Updatable] = []
    
    // MARK: - Methods
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        GameScene.viewportSize = view.bounds.size
        loadClouds()
        
        let joints = 100
        
//        waterNode = WaterNode(with: Float(self.size.width), numJoints: joints, surfaceHeight: Float(surfaceHeight), fillColor: waterColor)
        waterNode = DynamicWaterNode(width: Float(self.size.width), numJoints: joints, surfaceHeight: Float(surfaceHeight), fillColour: waterColor)
        waterNode.position = CGPoint(x: self.size.width / 2, y: 0)
        waterNode.zPosition = 8
        
        self.addChild(waterNode)
    }
    
    // MARK: - Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let box = DropNode(imageNamed: "Box")
            box.position = location
            box.zPosition = 15
            self.addChild(box)
            boxes.append(box)
        }
    }
    
    // MARK: - Update
    
    override func update(_ currentTime: TimeInterval) {
        if !hasReferenceFrameTime {
            deltaTime = currentTime
            hasReferenceFrameTime = true
            return
        }
        
        let dt = currentTime - deltaTime
        
        var accumuilator: TimeInterval = 0
        accumuilator += dt
        
        while accumuilator >=  fixedTimeStep {
            fixedUpdate(for: fixedTimeStep)
            accumuilator -= fixedTimeStep
        }
        fixedUpdate(for: accumuilator)
        
        lastUpdate(for: dt)
        deltaTime = currentTime
        
        // Iterate the updatables
        updatables.forEach{ $0.update(accumuilator) }
    }
    
    func fixedUpdate(for dt: CFTimeInterval) {
        waterNode.update(dt)
        
        var boxesToRemove = [DropNode]()
        let gravity: Double = -1200
        
        for box in boxes {
            box.velocity = CGPoint(x: box.velocity.x, y: box.velocity.y + CGFloat(gravity * dt))
            box.position = CGPoint(x: box.position.x + box.velocity.x * CGFloat(dt), y: box.position.y + box.velocity.y * CGFloat(dt))
            
            if box.isAboveWater && box.position.y <= CGFloat(waterNode.surfaceHeight) {
                box.isAboveWater = false
//                waterNode.splash(at: box.position.x, force: -box.velocity.y * splashForceMultiplier, width: Float(splashWidth))
                waterNode.splashAt(x: Float(box.position.x), force: -box.velocity.y * splashForceMultiplier, width: Float(splashWidth))
            }
            
            if box.position.y < -box.size.height / 2 {
                boxesToRemove.append(box)
            }
        }
        
        for box in boxesToRemove {
            guard let index = boxes.index(of: box) else {
                
                continue
            }
            debugPrint(#function + " remove box that is ourside of the viewport : ", boxes[index])
            let box = boxes[index]
            box.removeAllChildren()
            box.removeFromParent()
            boxes.remove(at: index)
        }
    }
    
    func lastUpdate(for dt: CFTimeInterval) {
        waterNode.render()
    }
    
}

extension GameScene {
    
    func loadClouds() {
        let spriteLoader = SerialSpriteUploader<CloudNode>(scene: self)
        let cloudsSprites = spriteLoader.upload(for: "cloud", with: { key, index -> String in
            return key + "-\(index)"
        }, inRange: 1...3)
        
        updatables.append(contentsOf: cloudsSprites)
    }
    
    fileprivate func debugWaterNodePrint() {
        DispatchQueue.once(token: "debug-print") {
            debugPrint(#function + " joints : ")
            
            waterNode.joints.forEach({ joint in
                debugPrint(joint.position)
            })
        }
    }
    
}

struct SerialSpriteUploader<Node: SKNode> {
    
    // MARK :- Properties
    
    private var scene: SKScene
    
    // MARK: - Initializers
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    // MARK: - Methods
    
    func upload(for key: String, with pattern: (_ key: String, _ index: Int)->String, inRange indices: ClosedRange<Int>) -> [Node] {
        
        var foundNodes = [Node]()
        
        for index in indices.lowerBound...indices.upperBound {
            let childName = pattern(key, index)
            guard let node = scene.childNode(withName: childName) as? Node else {
                debugPrint(#function + " could not find child with the following name: ", childName)
                continue
            }
            foundNodes.append(node)
        }
        
        return foundNodes
    }
}