import UIKit
import QuartzCore
import SceneKit
import CoreMotion

class GameViewController: UIViewController {
    
    let motionManager = CMMotionManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        // configure timestep
        scene.physicsWorld.timeStep = 1/300
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 2, z: 0)
        cameraNode.eulerAngles = SCNVector3(x: -Float(M_PI_2), y: 0, z: 0)
        
        let floor = SCNNode()
        let floorGeometry = SCNFloor()
        floorGeometry.reflectivity = 0
        floor.geometry = floorGeometry
        
        let floorPhysics = SCNPhysicsBody(type: .Static, shape: SCNPhysicsShape(geometry: floorGeometry, options: nil))
        floor.physicsBody = floorPhysics
        
        scene.rootNode.addChildNode(floor)
        
        let ball = SCNNode()
        let ballGeometry = SCNSphere(radius: 0.01)
        ball.geometry = ballGeometry
        ball.position = SCNVector3(x: 0, y: Float(ballGeometry.radius), z: 0)
        
        let ballPhysics = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: ballGeometry, options: nil))
        ballPhysics.mass = 1
        ball.physicsBody = ballPhysics
        
        scene.rootNode.addChildNode(ball)
        
        let accelerationMultiplier = Float(ballPhysics.mass) * 9.8
        
        let motionQueue = NSOperationQueue()
        motionManager.startAccelerometerUpdatesToQueue(motionQueue) { accelerometerData, err in
            let acceleration = accelerometerData.acceleration
            ballPhysics.applyForce(
                SCNVector3(x: Float(acceleration.x) * accelerationMultiplier, y: 0, z: -Float(acceleration.y) * accelerationMultiplier),
                impulse: false
            )
        }
        
        // add a wall
        let walls = (0...3).map { (w: Int) -> SCNNode in
            let wf = Float(w)
            let wallGeometry = SCNPlane(width: 1, height: 0.25)
            let wall = SCNNode(geometry: wallGeometry)
            wall.position = SCNVector3(
                x: ((wf % 2) / 2.0) * (w < 2 ? 1 : -1),
                y: 0.125,
                z: (((wf + 1) % 2) / 2.0) * (w < 2 ? -1 : 1))
            wall.physicsBody = SCNPhysicsBody(
                type: .Static,
                shape: nil)
            wall.eulerAngles = SCNVector3(x: 0, y: Float(M_PI_2)*(-wf), z: 0)
            
            println("\(wall.position.x) \(wall.position.y) \(wall.position.z): \(wall.eulerAngles.y)")
            return wall
        }
        
        for wall in walls {
            scene.rootNode.addChildNode(wall)
        }
        
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.whiteColor()
        
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
