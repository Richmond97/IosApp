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
    
    private var overlay: CALayer! = nil
    
    // Vision parts
    private var requests = [VNRequest]()
    override var prefersStatusBarHidden: Bool{
        return true
        
    }
    @IBOutlet weak var objectLable: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
   // var object = "nil"
    var highestScoreObj: AnyObject!
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
    //load the model
    func getModel() -> NSError?
    {
         let error: NSError! = nil
        //getting the model by defining its path
         guard let modelPath = Bundle.main.url(forResource: "TinyYOLOv3_VOC", withExtension: "mlmodelc")
            else
                {
                   return NSError(domain: "ObjectDetectiontionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "ERROR no Model"])
                }
        do {
            let myModel = try VNCoreMLModel(for: MLModel(contentsOf: modelPath))
            let objectRecognition = VNCoreMLRequest(model: myModel, completionHandler:
            {
                (request, error) in
            DispatchQueue.main.async(execute:
                {
                    // Executing all view upadtas in the main queue
                    if let results = request.results
                    {
                        self.objectsReturned(results)
                    }
                })
            })
            self.requests = [objectRecognition]
            }
            catch let error as NSError
            {
                print("ERROR I couldnt' add the model: \(error)")
            }
                  
                  return error
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        
        //Dividing the screen into 3 sections
        belowView.addSubview(drawLine(position: endLeftSide))
        belowView.addSubview(drawLine(position: endRightSide))
        belowView.addSubview(drawLine(position: endMiddleSide))
    }
    
    //set screen boundaries (Left, Center, Right)
    func initView(){
        let screen =  UIScreen.main.bounds
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
        rightSideRange = startRightSide...screen.height
    }
    func objectsReturned(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        overlay.sublayers = nil // resetting the view, by removing all detected object from thhe sublayer
        for obj in results where obj is VNRecognizedObjectObservation {
            guard let objectObservation = obj as? VNRecognizedObjectObservation else {
                continue
            }
            // Only the object with the hisgest score will be selected
            highestScoreObj = objectObservation.labels[0]
            
            let boxShape = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(buffeCapacity.width), Int(buffeCapacity.height))
            let boundingBoxLayer = self.boundingBox(boxShape)
            let contentLayer = self.createTextSubLayerInBounds(boxShape,objName: highestScoreObj.identifier,objSocre: highestScoreObj.confidence)
            boundingBoxLayer.addSublayer(contentLayer)
            overlay.addSublayer(boundingBoxLayer)
            
            
            
            
            //passing the detected object to MViewController
            //MainView
            //object is a global variable defined in MViewCtroller
            object = getObject()
            print(object)
               
        }
        self.layerConfigurationUpdate()
        CATransaction.commit()
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let bufferPxl = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let orientation = deviceOrientation()
        
        let ImgRequestManger = VNImageRequestHandler(cvPixelBuffer: bufferPxl, orientation: orientation, options: [:])
        do {
            try ImgRequestManger.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // setting Vision

        layerConfiguration()
        layerConfigurationUpdate()
        getModel()

        // starting capture session
        startCaptureSession()
    }
    
    //set object overlay
    func layerConfiguration() {
        overlay = CALayer() // container layer that has all the renderings of the observations
        overlay.bounds = CGRect(x: 0.0,y: 0.0,width: buffeCapacity.width, height: buffeCapacity.height)
        overlay.position = CGPoint(x: mainLayer.bounds.midX, y: mainLayer.bounds.midY)
        mainLayer.addSublayer(overlay)
    }
    
    //constantly update object overlay
    func layerConfigurationUpdate() {
        let boundingBox = mainLayer.bounds
        var scale: CGFloat
        
        let xAxis: CGFloat = boundingBox.size.width / buffeCapacity.height
        let yAxis: CGFloat = boundingBox.size.height / buffeCapacity.width
        
        scale = fmax(xAxis, yAxis)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // depending on scrren orientation adjust layer (scale, mirror)
        overlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        overlay.position = CGPoint (x: boundingBox.midX, y: boundingBox.midY)
        
        CATransaction.commit()
        
    }
    
    //defining the content of the bounding box
    func createTextSubLayerInBounds(_ objBox: CGRect, objName: String, objSocre: VNConfidence) -> CATextLayer {
        let contentLayer = CATextLayer()
        let label_score = NSMutableAttributedString(string: String(format: "\(objName)\nScore :  %.2f", objSocre))
        let font = UIFont(name: "Helvetica", size: 10.0)!
        label_score.addAttributes([NSAttributedString.Key.font: font], range: NSRange(location: 0, length: objName.count))
        contentLayer.string = label_score
        contentLayer.bounds = CGRect(x: 0, y: 0, width: objBox.size.height - 10, height: objBox.size.width - 10)
        contentLayer.shadowOffset = CGSize(width: 2, height: 2)
        contentLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        contentLayer.position = CGPoint(x: objBox.midX, y: objBox.midY)
        contentLayer.contentsScale = 2.0
        contentLayer.shadowOpacity = 0.4

        
        
        //passing the location of the object to MViewController
        //MainView
        //objPosition is a global variable defined in MViewCtroller
        objPosition = self.getObjectLocation(objectY: contentLayer.position.x)
        contentLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return contentLayer
    }
    
    //Setting the bounding box shape and color
    func boundingBox(_ objBox: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.bounds = objBox
        boxLayer.position = CGPoint(x: objBox.midX, y: objBox.midY)
        boxLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [2.0, 1.0, 0.2, 0.3])
        boxLayer.cornerRadius = 0
        return boxLayer
    }
    
    //Algotrithm { Avoid repeating the detect object to the user continuosly }
    func getObject() -> String{
               if highestScoreObj.confidence > 0.60 {
               
               object = highestScoreObj.identifier as String
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
   
    //Only for testing
    func getObjectTest(objects:[[String:Int]]) -> String{
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
    
    //passing the detected object location
    //in returning its position
    func getObjectLocation(objectY:CGFloat) -> String{
      //  self.initView() //uncomment for testing
        var position = "nil"
        
        if leftSideRange.contains(objectY){
            position = "on your left side"

        }
        else if rightSideRange.contains(objectY){
            position = "on your right side"

        }
        else if middleSideRange.contains(objectY){
            position = "in front of you"

        }
        return position
    }
    
    //function used to draw line in overlay
    func drawLine(position: CGFloat)->UIView{
        let lineView = UIView(frame: CGRect(x: 0, y: position, width: screen.width, height:2.0))
        lineView.layer.borderWidth = 1.0
        lineView.layer.borderColor = UIColor.red.cgColor
        return lineView
    }
}




//Reference
//******************************************************************************************************************************************************/
/*    Title:Recognizing Objects in Live Capture
 *    Author: Copyright © 2020 Apple Inc. All rights reserved.
 *    Date: 03/24/2020
 *    Code version: 1.0
 *    Availability: https://developer.apple.com/documentation/vision/recognizing_objects_in_live_capture
 *
*******************************************************************************************************************************************************/
