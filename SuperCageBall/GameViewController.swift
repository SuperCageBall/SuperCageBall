import UIKit
import QuartzCore
import SceneKit
//import SpriteKit
import CoreMotion

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    
    let cameraNode = SCNNode()
    let ball = SCNNode()
    let motionManager = CMMotionManager()
    
    @IBOutlet var scnView: SCNView!
    @IBOutlet var timerLabel: UILabel!
    
    let startTime = NSDate()
    var timer: NSTimer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        // configure timestep
        scene.physicsWorld.timeStep = 1/300
        
        // create and add a camera to the scene
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 2, z: 0)
        cameraNode.eulerAngles = SCNVector3(x: -Float(M_PI_2), y: 0, z: 0)
        
        let floor = SCNNode()
        let floorGeometry = SCNFloor()
        floorGeometry.reflectivity = 0
        floorGeometry.firstMaterial!.diffuse.contents = UIColor.lightGrayColor()
        floor.geometry = floorGeometry
        
        let floorPhysics = SCNPhysicsBody(type: .Static, shape: SCNPhysicsShape(geometry: floorGeometry, options: nil))
        floor.physicsBody = floorPhysics
        
        scene.rootNode.addChildNode(floor)
        
        let ballGeometry = SCNSphere(radius: 0.1)
        ball.geometry = ballGeometry
        ball.position = SCNVector3(x: 0, y: Float(ballGeometry.radius), z: 0)
        
        let ballPhysics = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: ballGeometry, options: nil))
        ballPhysics.mass = 1
        ball.physicsBody = ballPhysics
        
        // set color
        ball.geometry!.firstMaterial!.diffuse.contents = BallColor
        
        scene.rootNode.addChildNode(ball)
        
        let accelerationMultiplier = Float(ballPhysics.mass) * 9.8
        
        let motionQueue = NSOperationQueue()
        motionManager.startAccelerometerUpdatesToQueue(motionQueue) { accelerometerData, err in
            let acceleration = accelerometerData.acceleration
            let multiplier: Float = (UseAcceleration ? 1 : 0.5);
            let x = Float(acceleration.x) * accelerationMultiplier * multiplier
            let z = -Float(acceleration.y) * accelerationMultiplier * multiplier
            let vector = SCNVector3(x: x, y: 0, z: z)
            
            if UseAcceleration {
                ballPhysics.applyForce(
                    vector,
                    impulse: false
                )
            } else {
                ballPhysics.velocity = vector
            }
        }
        
        // add a wall
//        let walls = (0...3).map { (w: Int) -> SCNNode in
//            let wf = Float(w)
//            let wallGeometry = SCNPlane(width: 1, height: 0.25)
//            let wall = SCNNode(geometry: wallGeometry)
//            wall.position = SCNVector3(
//                x: ((wf % 2) / 2.0) * (w < 2 ? 1 : -1),
//                y: 0.125,
//                z: (((wf + 1) % 2) / 2.0) * (w < 2 ? -1 : 1))
//            wall.physicsBody = SCNPhysicsBody(
//                type: .Static,
//                shape: nil)
//            wall.eulerAngles = SCNVector3(x: 0, y: Float(M_PI_2)*(-wf), z: 0)
//            
//            println("\(wall.position.x) \(wall.position.y) \(wall.position.z): \(wall.eulerAngles.y)")
//            return wall
//        }
//        
//        for wall in walls {
//            scene.rootNode.addChildNode(wall)
//        }
        
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: -3)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        // set the scene to the view
        scnView.scene = scene
        
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.whiteColor()
        
        // setup delegate to handle callbacks at various stages of scene rendering
        scnView.delegate = self
        
        // overlay info
        // scnView.overlaySKScene = nil
        timer = NSTimer.scheduledTimerWithTimeInterval(1,
            target: self, selector: "timerTick", userInfo: nil, repeats: true)
        
        timerTick()
        
    }
    
    func timerTick() {
        let elapsed = -startTime.timeIntervalSinceNow
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Positional
        formatter.zeroFormattingBehavior = .Pad
        formatter.allowedUnits = .CalendarUnitMinute | .CalendarUnitSecond
        timerLabel.text = formatter.stringFromTimeInterval(elapsed)
    }
    
    func renderer(aRenderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        // fires when the ball goes outside of the camera view:
        let isBallVisible = scnView.isNodeInsideFrustum(ball.presentationNode(),
            withPointOfView: scnView.pointOfView)
        if !isBallVisible {
            // TODO Lose
            println("The ball is outside of the camera view!")
            scnView.delegate = nil
            motionManager.stopAccelerometerUpdates()
            dismissViewControllerAnimated(true, completion: nil)
        }
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
