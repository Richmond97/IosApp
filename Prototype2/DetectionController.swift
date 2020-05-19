import UIKit
import AVFoundation
import Vision

class DetectionController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var vc = SpeechSynthetizer()
    var buffeCapacity: CGSize = .zero
    var mainLayer: CALayer! = nil
   
    
    @IBOutlet weak public var belowView: UIView!
    private var belowLayer: AVCaptureVideoPreviewLayer! = nil
    private let vdOutput = AVCaptureVideoDataOutput()
    private let captureSession = AVCaptureSession()
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
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    }
    
    func startCaptureSession() {
        captureSession.startRunning()
    }
    func setupAVCapture() {
        var deviceInput: AVCaptureDeviceInput!
        
        // Choose device for video input
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
            
        } catch {
            print("ERROR video input failed: \(error)")
            return
        }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset =  .vga640x480 // adding the size of the image to be proccessed according to the model (416 x 416)
                                                    // model image input suze should be smaller
        
        // Add a video input
        guard captureSession.canAddInput(deviceInput) else {
            print("ERROR video session failed")
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(deviceInput)
        if captureSession.canAddOutput(vdOutput) {
            captureSession.addOutput(vdOutput)
            // Add a video data output
            vdOutput.alwaysDiscardsLateVideoFrames = true
            vdOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            vdOutput.setSampleBufferDelegate(self, queue: captureQueue)
        } else {
            print("ERROR failed to add video data to the session")
            captureSession.commitConfiguration()
            return
        }
        let captureConnection = vdOutput.connection(with: .video)
        //Esures that all frames are processed
        captureConnection?.isEnabled = true
        do {
            try  videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            buffeCapacity.width = CGFloat(dimensions.width)
            buffeCapacity.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        captureSession.commitConfiguration()
        belowLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        belowLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        mainLayer = belowView.layer
        belowLayer.frame = mainLayer.bounds
        mainLayer.addSublayer(belowLayer)
    }
    
    
    
    // Restart Avcapture
    func restartAVCapture() {
        belowLayer.removeFromSuperlayer()
        belowLayer = nil
    }
    

    
    public func deviceOrientation() -> CGImagePropertyOrientation {
        let orientation = UIDevice.current.orientation
        let currOrientation: CGImagePropertyOrientation
        
        switch orientation {
        case UIDeviceOrientation.portrait:
            currOrientation = .up
        case UIDeviceOrientation.portraitUpsideDown:
            currOrientation = .left
        case UIDeviceOrientation.landscapeRight:
            currOrientation = .down
        case UIDeviceOrientation.landscapeLeft:
            currOrientation = .upMirrored

        default:
            currOrientation = .up
        }
        return currOrientation
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


//**************************************************************************************/
/*    Title:Recognizing Objects in Live Capture
 *    Author: Copyright © 2020 Apple Inc. All rights reserved.
 *    Date: 03/24/2020
 *    Code version: 1.0
 *    Availability: https://developer.apple.com/documentation/vision/recognizing_objects_in_live_capture
 *
***************************************************************************************/
