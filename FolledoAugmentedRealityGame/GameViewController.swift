//
//  GameViewController.swift
//  FolledoAugmentedRealityGame
//
//  Created by Samuel Folledo on 2/28/18.
//  Copyright © 2018 Samuel Folledo. All rights reserved.
//

import ARKit

class GameViewController: UIViewController {
    
    var sceneView: ARSKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let view = self.view as? ARSKView {
            sceneView = view
            sceneView!.delegate = self
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            view.presentScene(scene)
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension GameViewController: ARSKViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session Failed - probably due to lack of camera access")
    }//session(_:didFailWithError:): will execute when the view can’t create a session. This generally means that to be able to use the game, the user will have to allow access to the camera through the Settings app. This is a good spot to display an appropriate dialog.
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session interrupted")
    }//sessionWasInterrupted(_:): means that the app is now in the background. The user may have pressed the home button or received a phone call.
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("Session resumed")
        sceneView.session.run(session.configuration!,
                              options: [.resetTracking,
                                        .removeExistingAnchors])
    }//sessionInterruptionEnded(_:): means that play is back on again. The camera won’t be in exactly the same orientation or position so you reset tracking and anchors
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? { //When you add an anchor, the session calls sceneView’s delegate method view(_:nodeFor:) to find out what sort of SKNode you want to attach to this anchor p.657
        var node: SKNode?
        if let anchor = anchor as? Anchor {
            if let type = anchor.type {
                node = SKSpriteNode(imageNamed: type.rawValue)
                node?.name = type.rawValue
            }
        }
        return node
    }
}



