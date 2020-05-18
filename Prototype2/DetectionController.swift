import UIKit
import AVFoundation
import Vision

class DetectionController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    var vc = SpeechSynthetizer()
    
    @IBOutlet weak public var belowView: UIView!
    private let session = AVCaptureSession()
    private var belowLayer: AVCaptureVideoPreviewLayer! = nil
    private let vdOutput = AVCaptureVideoDataOutput()
    
    private let captureQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // this will be used in in the ObjetcDetection class
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAVCapture()
        self.title =  "Object Detection"
        vc.startSpeaking(messaage: "HI, i am your voice assistant, tap to begin ",type: "indication")
    }
    @IBAction func tapGesture(){
        let vc = storyboard?.instantiateViewController(identifier: "maps") as! MViewController
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupAVCapture() {
        var deviceInput: AVCaptureDeviceInput!
        
        // Choose device for video input
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
            
        } catch {
            print("ERROR Could video input failed: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset =  .vga640x480 // Model image size is smaller.
        
        // Add a video input
        guard session.canAddInput(deviceInput) else {
            print("ERROR video session failed")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        if session.canAddOutput(vdOutput) {
            session.addOutput(vdOutput)
            // Add a video data output
            vdOutput.alwaysDiscardsLateVideoFrames = true
            vdOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            vdOutput.setSampleBufferDelegate(self, queue: captureQueue)
        } else {
            print("ERROR failed to add video data to the session")
            session.commitConfiguration()
            return
        }
        let captureConnection = vdOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            try  videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
        belowLayer = AVCaptureVideoPreviewLayer(session: session)
        belowLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        rootLayer = belowView.layer
        belowLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(belowLayer)
    }
    
    func startCaptureSession() {
        session.startRunning()
    }
    
    // Clean up capture setup
    func teardownAVCapture() {
        belowLayer.removeFromSuperlayer()
        belowLayer = nil
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // print("frame dropped")
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}
extension UIViewController
    {
    @objc func myswipeAction(swipe:UISwipeGestureRecognizer)
        {
            switch swipe.direction.rawValue
            {   case 1:
                    performSegue(withIdentifier: "swipeRight", sender: self)
                case 2:
                    performSegue(withIdentifier: "swipeLeft", sender: self)
                default:
                    break
            }
        }
    }

