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
    var mvv = MVVControllerViewController()
    
    // Vision parts
    private var requests = [VNRequest]()
    override var prefersStatusBarHidden: Bool{
        return true
        
    }
    @IBOutlet weak var objectLable: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    var object = "nil"
    var topLabelObservation: AnyObject!
    
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
    
    func objectRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
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
            mvv.object = object
          //  var o = segue.destination as! MVVControllerViewController
         //   o.object = self.object
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
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence Score:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
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

        }
        return object
    }
 /*   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var o = segue.destination as! MVVControllerViewController
        o.object = self.object
    }*/
 /*   @IBAction func start(_ sender: Any) {
        func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "startMap"{
                _ = segue.destination as! MVVControllerViewController
            }
        }
    }*/
}


