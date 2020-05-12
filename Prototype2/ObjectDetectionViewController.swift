//
//  ObjectDetectionViewController.swift
//  Prototype2
//
//  Created by Richmond Yeboah on 31/01/2020.
//  Copyright © 2020 Richmond Yeboah. All rights reserved.
//

import UIKit
import AVKit
import Vision
import VisionKit
import AVFoundation
import TensorFlowLite



class ObjectDetectionViewController: DetectionController {
    
    private var detectionOverlay: CALayer! = nil
    
    // Vision parts
    private var requests = [VNRequest]()
    override var prefersStatusBarHidden: Bool{
        return true
        
    }
    @IBOutlet weak var objectLable: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
   // var object = "nil"
    var topLabelObservation: AnyObject!
    var listObject: Array = ["nil","nil","nil"]
    var line = UIBezierPath()
    var screen =  UIScreen.main.bounds
    let sectionWidth = CGFloat()
    //Left side bounds
    var startLeftSide = 0.0 as CGFloat
    var endLeftSide = CGFloat()
    var leftSideRange:ClosedRange<CGFloat> = 0...0
    //middle part bounds
    var startMiddleSide = CGFloat()
    var endMiddleSide = CGFloat()
    var middleSideRange:ClosedRange<CGFloat> = 0...0
    //right side bounds
    var startRightSide = CGFloat()
    var endRightSide = CGFloat()
    var rightSideRange:ClosedRange<CGFloat> = 0...0
    //test variable
    var objects:[[String:Int]]!
    var index = 0
    var result: String = "nil"
    
    @discardableResult
    func modelSetup() -> NSError?
    {
         let error: NSError! = nil
         guard let modelURL = Bundle.main.url(forResource: "YOLOv3Tiny", withExtension: "mlmodelc")
            else
                {
                   
                   return NSError(domain: "ObjectDetectiontionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
                }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler:
            {
                (request, error) in
            DispatchQueue.main.async(execute:
                {
                    // perform all the UI updates on the main queue
                    if let results = request.results
                    {
                        self.objectRequestResults(results)
                    }
                })
            })
            self.requests = [objectRecognition]
            }
            catch let error as NSError
            {
                print("Couldnt'Load the model: \(error)")
            }
                  
                  return error
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()

        belowView.addSubview(drawLine(position: endLeftSide))
        belowView.addSubview(drawLine(position: endRightSide))
        belowView.addSubview(drawLine(position: endMiddleSide))
    }
    
    func initView(){
        var screen =  UIScreen.main.bounds
        let sectionWidth = screen.height / 3
        //Left side bounds
        startLeftSide = 0.0 as CGFloat
        endLeftSide = startLeftSide + sectionWidth
        leftSideRange = startLeftSide...endLeftSide
        //middle part bounds
        startMiddleSide = endLeftSide + 0.01
        endMiddleSide = startMiddleSide + sectionWidth
        middleSideRange = startMiddleSide...endMiddleSide
        //right side bounds
        startRightSide = endMiddleSide + 0.01
        endRightSide = startRightSide + sectionWidth
        rightSideRange = startRightSide...endRightSide
        print("right side range :  \(rightSideRange)")
    }
    func objectRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the object with the highest confidence.
            topLabelObservation = objectObservation.labels[0]
            
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: topLabelObservation.identifier,
                                                            confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
            object = getObject()
            print(object)
               
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // setup Vision parts

        layersSetup()
        updateLayerGeometry()
        modelSetup()

        // start the capture
        startCaptureSession()
    }
    
    func layersSetup() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
       detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint (x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object "
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence :  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 14.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        objPosition = self.getObjLocatio(objectY: textLayer.position.x)
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }

    func getObject() -> String{
               if topLabelObservation.confidence > 0.60 {
               
               object = topLabelObservation.identifier as String
                if listObject[0] == "nil"{
                    listObject[0] = object
                    return "nil"
                }
                else{
                    if listObject[1] == "nil"{
                        listObject[1] = object
                        return "nil"
                    }
                    else{
                        if listObject[0] == listObject[1] {
                            listObject[0] = object
                            listObject[1] = "nil"
                            object = "nil"
                        }
                        else{
                            listObject[0] = object
                            listObject[1] = "nil"              }
                    }
                }
            }
            else{
                object = "nil"
            }
            listObject[0] = "nil"
            listObject[1] = "nil"
            return object
    }
    
    func getObjectTest(objects:[[String:Int]]) -> String{
        
      //  var listObject: Array = ["nil","nil","nil"]
          let newObj = objects[index]
          index += 1
            for (name,confidence) in newObj{
               if confidence > 60 {
                   if listObject[0] == "nil"{
                       listObject[0] = name
                    getObjectTest(objects: objects)
                   }
                   else{
                       if listObject[1] == "nil"{
                           listObject[1] = name
                        getObjectTest(objects: objects)
                       }
                       else{
                           if listObject[0] == listObject[1] {
                            print (listObject[0],listObject[1])
                               listObject[0] = name
                               listObject[1] = "nil"
                               result = "nil"
                           }
                           else{
                               listObject[0] = name
                               listObject[1] = "nil"
                               result = name
                           }
                       }
                   }
               }
               else{
               }
               
            }
        return result
    }
    
    func getObjLocatio(objectY:CGFloat) -> String{
        self.initView()
        var position = "nil"
        
        if leftSideRange.contains(objectY){
            position = "on your left side"

        }
        else if middleSideRange.contains(objectY){
            position = "in front of you"

        }
        else if rightSideRange.contains(objectY){
            position = "on your right side"

        }
        return position
    }
    
    func drawLine(position: CGFloat)->UIView{
        let lineView = UIView(frame: CGRect(x: 0, y: position, width: screen.width, height:2.0))
        lineView.layer.borderWidth = 1.0
        lineView.layer.borderColor = UIColor.red.cgColor
        return lineView
    }
}


