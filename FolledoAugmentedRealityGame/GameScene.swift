//
//  GameScene.swift
//  FolledoARGame
//
//  Created by Samuel Folledo on 10/21/17.
//  Copyright © 2017 Samuel Folledo. All rights reserved.

import ARKit

class GameScene: SKScene { //5 p. 653
    var sceneView: ARSKView {
        return view as! ARSKView
    }
    var isWorldSetUp = false //5
    var sight:SKSpriteNode!//sight for shooting bugs p.659
    
    let gameSize = CGSize(width: 2, height: 2)//p.662
    var hasBugspray = false {//alternate between sight if hasBugSpray is true
        didSet {
            let sightImageName = hasBugspray ? "bugspraySight" : "sight"
            sight.texture = SKTexture(imageNamed: sightImageName)
        }
    }
    
    override func didMove(to view: SKView) {
        sight = SKSpriteNode(imageNamed: "sight")
        addChild(sight) //automatically puts it in the middle because anchor point is 0,0
        
        srand48(Int(Date.timeIntervalSinceReferenceDate))//to seed the random number generator, so it wont be the same random over and over again
    }
    
    //5
    override func update(_ currentTime: TimeInterval) {
        if !isWorldSetUp{
            setUpWorld()
        }
        
        //8 retrieve the light estimate from the session's current frame p.658
        guard let currentFrame = sceneView.session.currentFrame,
            let lightEstimate = currentFrame.lightEstimate else {
                return
        }
        //8 the measure of light is lumens, and 1000 lumens is a fairly bright light. Using the light estimate's intensity of ambient light in the scene, you calculate a blend factor between 0 and 1, where 0 will be the brightest
        let neutralIntensity: CGFloat = 1000
        let ambientIntensity = min(lightEstimate.ambientIntensity, neutralIntensity)
        let blendFactor = 1 - ambientIntensity / neutralIntensity
        //8 using this blend factor, the device will calculate available light, when no light, the bug will be shaded
        for node in children {
            if let bug = node as? SKSpriteNode{
                bug.color = .black
                bug.colorBlendFactor = blendFactor
            }
        }
    }//end of update
    
    
    //5 setUpWorld
    private func setUpWorld(){
        guard let currentFrame = sceneView.session.currentFrame,
            let scene = SKScene(fileNamed: "FolledoARLevel1.sks") //load scene with the bugs from FolledoARLevel1.sks
            else {return} ////this allows to load the bug once only if isWorld false; to make sure the AR session is ready
        
        for node in scene.children { //-.662
            if let node = node as? SKSpriteNode {
                var translation = matrix_identity_float4x4 //6 p.655 Createa four-dimensional identity matrix
                //translation.columns.3.z = -0.3
                //11 p.663 You calculate the position of the node relative to the size of the scene. ARKit translations are measured in meters. Turning 2D into 3D, you use the y-coordinate of the 2D scene as the z-coordinate in 3D space. Using these values, you create the                anchor and the view’s delegate will add the SKSpriteNode bug for each anchor as                    before.
                let positionX = node.position.x / scene.size.width
                let positionY = node.position.y / scene.size.height
                translation.columns.3.x = Float(positionX * gameSize.width)
                translation.columns.3.z = -Float(positionY * gameSize.height)
                translation.columns.3.y = Float(drand48() - 0.5) //p.664 creates a random value between -0.5 and 0.5 and assign it to the translation matrix
                let transform = currentFrame.camera.transform * translation //6 p.656 multiply the transform matrix of the current frame's camera by your translation matrix.
                //let anchor = ARAnchor(transform: transform)
                //sceneView.session.add(anchor: anchor) //adds an achor to the session. The anchor is now a permanent feature in your 3D world until u remove it. Each frame tracks this anchor and recalculates the transfomation matrices of teh anchors and teh camera using the device's new position and orientation p.656
                //previous 2 lines has been replaced with the following
                let anchor = Anchor(transform: transform)
                if let name = node.name,
                    let type = NodeType(rawValue: name) {
                    anchor.type = type
                    sceneView.session.add(anchor: anchor)
                    if anchor.type == .firebug {
                        addBugSpray(to: currentFrame)
                    }
                }
            }
        }
        isWorldSetUp = true
    }//end of setUpWorld
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = sight.position
        let hitNodes = nodes(at: location) //Here you retrieve an array of all the nodes that intersect the same xy location as the sight
        
        var hitBug: SKNode?
        /*
         for node in hitNodes{ //You’ll now find out if any of these nodes are a bug, and if they are, retrieve the first one
         if node.name == "bug" {
         hitBug = node
         break
         }
         }
         */
        for node in hitNodes { //replacement of the previous for loop
            if node.name == NodeType.bug.rawValue ||
                (node.name == NodeType.firebug.rawValue && hasBugspray) {
                hitBug = node
                break
            }
        }
        
        run(Sounds.fire) //play a sound to indicate user have fired
        if let hitBug = hitBug, let anchor = sceneView.anchor(for: hitBug){ //If you do hit a bug, then play the hit sound after a short delay to indicate the bug is some distance away. Then remove the anchor for the node, which will also remove the bug node itself.
            let action = SKAction.run{
                self.sceneView.session.remove(anchor: anchor)
            }
            let group = SKAction.group([Sounds.hit,action])
            let sequence = [SKAction.wait(forDuration: 0.3), group]
            hitBug.run(SKAction.sequence(sequence))
        }
        
        hasBugspray = false
    }
    
    private func addBugSpray(to currentFrame: ARFrame) {
        var translation = matrix_identity_float4x4
        translation.columns.3.x = Float(drand48()*2 - 1)
        translation.columns.3.z = -Float(drand48()*2 - 1)
        let transform = currentFrame.camera.transform * translation
        let anchor = Anchor(transform: transform)
        anchor.type = .bugspray
        sceneView.session.add(anchor: anchor)
    }
    
    private func remove(bugspray anchor: ARAnchor) {
        run(Sounds.bugspray)
        sceneView.session.remove(anchor: anchor)
        hasBugspray = true
    }
}


