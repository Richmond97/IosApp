//
//  MVVControllerViewController.swift
//  Prototype2
//
//  Created by Richmond Yeboah on 26/04/2020.
//  Copyright © 2020 Richmond Yeboah. All rights reserved.
//

import UIKit
import MapKit
import Speech
import CoreLocation
import AVFoundation


class MVVControllerViewController: UIViewController {
    
    
    

    @IBOutlet weak var tapGesture: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var voiceActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var lblDirection: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
        let vc = SpeechSynthetizer()
    
    //@IBOutlet var tapGesture: UITapGestureRecognizer!
    var eachStep = [MKRoute.Step]()
    let speachSynthesizer = AVSpeechSynthesizer()
    let locationManger = CLLocationManager()
    var currentCoordinate: CLLocationCoordinate2D!
    
    var instructions: String = "000"
    var tasksSequence: Array = [1,0,0,0,0]
    var stepsCount = 0
    var currStep = 0
    var tapCount = 0
    var tapCount1 = 0
    var locationUserSaid = "nil"
    var desiredlocation = "nil"
    var running = true
    var object: String = ""
 
    override func viewDidLoad() {
        
        
        locationManger.requestAlwaysAuthorization()
        locationManger.delegate = self
        locationManger.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManger.startUpdatingLocation()
      //  tapGesture.isEnabled = true
        super.viewDidLoad()
        vc.startSpeaking(messaage: "HI, i am your voice assistant, tap to begin ")
        delegateDetectedObject()

    }

    
  /*  @IBAction func tapGestureAction(_ sender: Any) {

        if  audioEngine.isRunning{
            voiceActivityIndicator.stopAnimating()
            audioEngine.stop()
            recognitionReq?.endAudio()
            tapGesture.isEnabled = false
            lblTitle.text = "Record"
        }else{
            voiceActivityIndicator.startAnimating()
            startListening()
            lblTitle.text = "Stop"
        }
    }*/
    
    func calculateNextMove(to nextTurn: MKRoute.Step) -> Array<Any>{
        var nextTurnInfo: Array<Any> = []
        let distance = nextTurn.distance
        let info = nextTurn.instructions
        nextTurnInfo.append(distance)
        nextTurnInfo.append(info)
        return nextTurnInfo
    }
    func userIsSpeaking(withCompletionHandler completionHandler: @escaping((_ instruction: String, _ finshed: Bool) -> Void)){
        if  vc.audioEngine.isRunning{
            lblTitle.text = "stoped recording"
            voiceActivityIndicator.stopAnimating()
            vc.audioEngine.stop()
            vc.recognitionReq?.endAudio()
            delegateDetectedObject()
        }else{
            lblTitle.text = "now recording"
            voiceActivityIndicator.startAnimating()
            vc.startListening { (location, finished) in
                if finished{
                    completionHandler(location,true)
                }
                else{
                completionHandler("",false)
                }
            }
            delegateDetectedObject()
            //self.mapOps.geocodeAdr(address: address, withCompletionHandler: { (status, success) -> Void in
        }
    }
    func getDirections(to destionation: MKMapItem){
        let sourceMark = MKPlacemark(coordinate: currentCoordinate)
        let sourceDirection = MKMapItem(placemark: sourceMark)
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceDirection
        directionRequest.destination = destionation
        directionRequest.transportType = .walking
        delegateDetectedObject()
        let direction = MKDirections(request: directionRequest)
        direction.calculate { (response, error) in
            guard let response = response else { return }
            guard let mainPath = response.routes.first  else { return }
            
            self.locationManger.monitoredRegions.forEach({ self.locationManger.stopMonitoring(for: $0) })
            
            self.mapView.addOverlay(mainPath.polyline)
            self.eachStep = mainPath.steps
            
            // print(self.eachStep.first(where: <#T##(MKRoute.Step) throws -> Bool#>))
            for i in 0 ..< mainPath.steps.count {
                let  currStep = i
             //   print(" eachStep is: \(self.eachStep)")
                let nextStep = mainPath.steps[i]
             //   print(nextStep.instructions)
            //    print(nextStep.distance)
               print("yes")
                let turnRegion = CLCircularRegion(center: nextStep.polyline.coordinate,
                                          radius: 10,
                                          identifier: "\(i)")
                self.locationManger.startMonitoring(for: turnRegion)
               // (for: turnRegion)
                let radius = MKCircle(center: turnRegion.center, radius: turnRegion.radius)
                self.mapView.addOverlay(radius)
                self.stepsCount += 1
                //
                let nextMove = self.calculateNextMove(to: self.eachStep[currStep])
             //   let distance = nextMove[0]
               // let info = nextMove[0]
            }
        }
    }
    func searchLocation(location:String){
        let searchRequest = MKLocalSearch.Request()
                    searchRequest.naturalLanguageQuery = location
                    let region = MKCoordinateRegion(center:currentCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.1
                        , longitudeDelta: 0.1))
                    searchRequest.region = region
                    let nearestSearch = MKLocalSearch(request: searchRequest)
                    nearestSearch.start { (response, _) in
                        guard let response = response else {return}
                        print(response.mapItems.first!)
                        //grab first item
                        guard let location = response.mapItems.first else{return}
                        self.getDirections(to: location)
                        self.delegateDetectedObject()
        }
    }
    func getLoactionTask(withCompletionHandler completionHandler: @escaping((_ location: String, _ finshed: Bool) -> Void)){
        self.userIsSpeaking { (location, finished) in
            if finished{
                print("end reocrding")
                completionHandler(location,true)
                self.delegateDetectedObject()
            }
        else{
         //   DispatchQueue.global(qos: .background).async{
                self.vc.startSpeaking(messaage: "Where would you like to go?")
                print("Where would you like to go?")
        //    }
                completionHandler("",false)
        }
       
    }
}
    func questionconfirmLoactioTask(location: String){
        
        print("confirming location")
        vc.startSpeaking(messaage: "You would like to got to \(location), is that correct?")
        print("You would like to got to \(location), is that correct?")
    }
    func responseLocationConfirmation(location: String,withCompletionHandler completionHandler: @escaping((_ response: String, _ finshed: Bool) -> Void)){
      //  var confirmed = "nil"
        self.userIsSpeaking { (answer, finished) in
            if finished {
                if answer == "Yes"{
                    completionHandler( answer, true)
                    
                }
                else if answer == "No"{
                   // DispatchQueue.main.async{
                    self.vc.startSpeaking(messaage: "Sorry, I didn't get that")
                    completionHandler( answer, false)
                    print("Sorry, I didn't get that")
                 //   self.getLoactionTask { (location, finished) in
                //    }
               //     self.questionconfirmLoactioTask(location: location)
               //     self.responseLocationConfirmation(location: location) { (response, finished) in
                  //  }
                      //  }
                }
                else{
                  //  DispatchQueue.main.async{
                    self.vc.startSpeaking(messaage: "Pleas answer with a yes or no")
                    print("Pleas answer with a yes or no")
                    self.questionconfirmLoactioTask(location: location)
              //      self.responseLocationConfirmation(location: location) { (response, finished) in
                //    }
                    completionHandler( "unkwon", false)
            }
        }
                
            else{
                print("started listening")
            }
        }
    }
    func delegateDetectedObject(){
            print("detected object is:  \(object)")
    }
 
    func test(){
        for i in 0...50{
            if i == 10{
                delegateDetectedObject()
            }
        }
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        delegateDetectedObject()
        //get location
        if tasksSequence[0] == 1{
            if tapCount < 2{
                self.getLoactionTask { (location, finished) in
                    if finished{
                        self.desiredlocation = location
                        return
                    }
                }
                //go to next task
                if tapCount == 1 {
                    tasksSequence[0] = 0
                    tasksSequence[1] = 1
                    tapCount = 0
                    return
                    }
                else{
                    self.tapCount =  self.tapCount + 1
                        return
                }
            }
        }
        else if tasksSequence[1] == 1{
             tasksSequence[1] = 0
             questionconfirmLoactioTask(location: desiredlocation)
                 tasksSequence[2] = 1
             return
         }
          //answer to confirm location
              //responce to confirm location
          else if tasksSequence[2] == 1{
                  if tapCount1 < 2{
                            self.responseLocationConfirmation(location: desiredlocation) { (response, finished) in
                                if response == "Yes"{
                                    self.searchLocation(location: self.desiredlocation)
                                }
                                else if response == "No"{
                                    self.desiredlocation = ""
                                    self.tasksSequence[0] = 1
                                    self.tasksSequence[2] = 0
                                    self.tapCount1 = 0
                                    return
                                }
                                else if response == "unkwon" {
                                    self.tasksSequence[1] = 1
                                    self.tasksSequence[2] = 0
                                }
                        }
                    if tapCount1 == 1{
                        tasksSequence[2] = 0
                        tasksSequence[3] = 1
                        tapCount1 = 0
                        return
                    }
                    else{
                        tapCount1 = tapCount1 + 1
                        return
                    }
            }
            
        }
        
    }
}
    
//get User current location 
extension MVVControllerViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        guard let currLocation = locations.first else {return}
        currentCoordinate = currLocation.coordinate
        print("my location is \(currentCoordinate)")
      //  mapView.userTrackingMode = .followWithHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    print("in region")
   // stepsCount += 1
    if stepsCount < eachStep.count {
        let currentStep = eachStep[stepsCount]
        let message = "In \(currentStep.distance) meters, \(currentStep.instructions)"
        lblDirection.text = message
        let speechUtterance = AVSpeechUtterance(string: message)
        speachSynthesizer.speak(speechUtterance)
    } else {
        let message = "Arrived at destination"
        lblDirection.text = message
        let speechUtterance = AVSpeechUtterance(string: message)
        speachSynthesizer.speak(speechUtterance)
        stepsCount = 0
        }
    }
}
//Search location
/*extension MVVControllerViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        let region = MKCoordinateRegion(center:currentCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.1
            , longitudeDelta: 0.1))
        searchRequest.region = region
        let nearestSearch = MKLocalSearch(request: searchRequest)
        nearestSearch.start { (response, _) in
            guard let response = response else {return}
            print(response.mapItems.first)
            //grab first item
            guard let desiredLocation = response.mapItems.first else{return}
            self.getDirections(to: desiredLocation)
        }
    }*/
//Display path
extension MVVControllerViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline{
            let render = MKPolylineRenderer(overlay: overlay)
            render.lineWidth = 5
            render.strokeColor = .blue
            return render
        }
        
        if overlay is MKCircle{
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.alpha = 0.3
            circleRenderer.fillColor = .orange
            circleRenderer.strokeColor = .yellow
            
        }
        return MKOverlayRenderer()
    }
}

/*extension MVVControllerViewController: SFSpeechRecognizerDelegate{

   public func startListening() /*-> String*/ {
        if speechReqTask != nil{
            speechReqTask?.cancel()
            speechReqTask = nil
        }
        let listeningSession = AVAudioSession.sharedInstance()
        do{
            try listeningSession.setCategory(.record, mode: .measurement, options: .duckOthers)
          //  try listeningSession.setActive(true, options: .notifyOthersOnDeactivation)
        }catch{
            print("Audio session failed to setup")
        }
    
        recognitionReq = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionReg = recognitionReq else {
            fatalError("Request Instance failed")
        }
    
        recognitionReq?.shouldReportPartialResults = true
        speechReqTask = speechRecognizer?.recognitionTask(with: recognitionReg){
            result, error in
            var isLast = false
            if result != nil{
                isLast = (result?.isFinal)!
            }
            //error != nil ||
            if  error != nil || isLast{
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionReq = nil
                self.speechReqTask = nil
                self.tapGesture.isEnabled = true
                let tts = result?.bestTranscription.formattedString
                self.lblDirection.text = tts
                print("you said: \(String(describing: tts))")
            }
            else if error != nil{
                print(error)
            }
        }
    let audioFormat = inputNode.outputFormat(forBus: 0)
     inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat){
       (audioBuffer: AVAudioPCMBuffer, when: AVAudioTime)
        in
         self.recognitionReq?.append(audioBuffer)
     }
         self.audioEngine.prepare()
     do{
         try self.audioEngine.start()
         
     }catch{
         print("failed to start engine")
         
         }
    }
}
*/
