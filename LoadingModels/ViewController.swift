//
//  ViewController.swift
//  LoadingModels
//
//  Created by Abdulfatah Mohamed on 23/11/2022.
//

import UIKit
import SceneKit
import ARKit

enum BodyType : Int {
    case box = 1
    case plane = 2
    case car = 3
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var planes = [OverlayPlane]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]

        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        self.sceneView.scene.lightingEnvironment.contents = UIImage(named: "background-light.JPG")
        
        registerGestureRecognizers()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        let estimate = self.sceneView.session.currentFrame?.lightEstimate
        if estimate == nil {
            return
        }
        
        let intensity = (estimate?.ambientIntensity)! / 1000.0
        self.sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    private func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        
        let doubleTappedGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTappedGestureRecognizer.numberOfTapsRequired = 2
        
        tapGestureRecognizer.require(toFail: doubleTappedGestureRecognizer)
        
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(doubleTappedGestureRecognizer)
    }
    
    @objc func doubleTapped(recognizer: UIGestureRecognizer) {
        self.sceneView.debugOptions = []
        
        let configuration = self.sceneView.session.configuration as! ARWorldTrackingConfiguration
        
        configuration.planeDetection = []
        self.sceneView.session.run(configuration, options: [])
        
        // turn off the grid
        for plane in self.planes {
            plane.planeGeometry.materials.forEach { material in
                material.diffuse.contents = UIColor.clear
            }
        }
    }
    
    @objc func tapped(recognizer: UIGestureRecognizer) {
        
        let sceneView = recognizer.view as! ARSCNView
        let touch = recognizer.location(in: sceneView)
        
        guard let query = sceneView.raycastQuery(from: touch,
                                                         allowing: .existingPlaneInfinite,
                                                         alignment: .any) else {
            return
        }
        
        let hitResults = sceneView.session.raycast(query)
        
        if !hitResults.isEmpty {
            guard let hitResult = hitResults.first else {
                return
            }
            
            addBench(hitResult: hitResult)
        }
    }
    
    private func addBench(hitResult: ARRaycastResult) {
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/bench.dae")
        
        let benchNode = scene?.rootNode.childNode(withName: "SketchUp", recursively: true)
        
        benchNode?.position = SCNVector3(hitResult.worldTransform.columns.3.x,
                                         hitResult.worldTransform.columns.3.y,
                                         hitResult.worldTransform.columns.3.z)
        benchNode?.scale = SCNVector3(0.5, 0.5, 0.5)
        
        self.sceneView.scene.rootNode.addChildNode(benchNode!)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if !(anchor is ARPlaneAnchor) {
            return
        }
        
        let plane = OverlayPlane(anchor: anchor as! ARPlaneAnchor)
        self.planes.append(plane)
        node.addChildNode(plane)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        let plane = self.planes.filter { plane in
            return plane.anchor.identifier == anchor.identifier
        }.first
        
        if plane == nil {
            return
        }
        
        plane?.update(anchor: anchor as! ARPlaneAnchor)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
