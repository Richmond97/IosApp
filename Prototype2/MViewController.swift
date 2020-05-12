//
//  MViewController.swift
//  Prototype2
//
//  Created by Richmond Yeboah on 01/05/2020.
//  Copyright © 2020 Richmond Yeboah. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import MapKit

var object: String = "nil"
var objPosition: String = "nil"


class MViewController: UIViewController {

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
         var currentLocation: CLLocation!
    
         
         var instructions: String = "000"
         var tasksSequence: Array = [1,0,0,0,0]
         var stepsCount = 0
         var currStep = 0
         var tapCount = 0
         var tapCount1 = 0
         var locationUserSaid = "nil"
         var desiredlocation = "nil"
         var running = true
         var count = 0
         var giveSeconfIns = false
    
         var expectedTravelTime: TimeInterval = 0
         var nameOfDestination = "unknown"
      
         override func viewDidLoad() {
             
             
             locationManger.requestAlwaysAuthorization()
             locationManger.delegate = self
             locationManger.desiredAccuracy = kCLLocationAccuracyBest
             locationManger.activityType = .fitness
             locationManger.startUpdatingLocation()
            
           //  tapGesture.isEnabled = true
             super.viewDidLoad()
             vc.startSpeaking(messaage: "HI, i am your voice assistant, tap to begin ")
            
         }


        
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    func calculateNextMove(to nextTurn: MKRoute.Step) -> Array<Any>{
            var nextTurnInfo: Array<Any> = []
            let distance = nextTurn.distance
            let info = nextTurn.instructions
            nextTurnInfo.append(distance)
            nextTurnInfo.append(info)
            return nextTurnInfo
        }
    func alertStartingJourney(){
            expectedTravelTime = expectedTravelTime / 60
            self.vc.startSpeaking(messaage: "Ok let's begin, I am taking you to  \(self.nameOfDestination), and will roughly take about \(Int(self.expectedTravelTime)) minutes")
            self.delay(10){
                self.vc.startSpeaking(messaage: "proceed straight for \(self.eachStep[0].distance) meters, \(self.eachStep[0].instructions)")
            }
        }
    func userIsSpeaking(withCompletionHandler completionHandler: @escaping((_ instruction: String, _ finshed: Bool) -> Void)){
            if  vc.audioEngine.isRunning{
                lblTitle.text = "stoped recording"
                voiceActivityIndicator.stopAnimating()
                vc.audioEngine.stop()
                vc.recognitionReq?.endAudio()
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
            }
        }
    func getDirections(to destionation: MKMapItem){
        let sourceMark = MKPlacemark(coordinate: currentCoordinate)
        let sourceDirection = MKMapItem(placemark: sourceMark)
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceDirection
        directionRequest.destination = destionation
        directionRequest.transportType = .walking
        let direction = MKDirections(request: directionRequest)
        direction.calculate { (response, error) in
            guard let response = response else { return }
            guard let mainPath = response.routes.first  else { return }
            self.expectedTravelTime =  mainPath.expectedTravelTime
            
            self.mapView.addOverlay(mainPath.polyline)
            
            // self.locationManger.monitoredRegions.forEach({ self.locationManger.stopMonitoring(for: $0) })
            
            self.eachStep = mainPath.steps
            for i in 0 ..< mainPath.steps.count {
                let  currStep = i
                
                // print("the var eachStep is:\(self.eachStep)")
                
                let nextStep = mainPath.steps[i]
                print(nextStep.instructions)
                print(nextStep.distance)
                
                let turnRegion = CLCircularRegion(center: nextStep.polyline.coordinate,
                                            radius: 20,
                                            identifier: "\(i)")
                self.locationManger.startMonitoring(for: turnRegion)
                
                // (for: turnRegion)
                let mradius = MKCircle(center: turnRegion.center, radius: turnRegion.radius)
                turnRegion.notifyOnEntry = true
                self.mapView.addOverlay(mradius)
                //   self.stepsCount += 1
                //
                let nextMove = self.calculateNextMove(to: self.eachStep[currStep])
                let distance = nextMove[0]
                let info = nextMove[0]
            }
            self.alertStartingJourney()
        }
    }
    func searchLocation(location:String,withCompletionHandler completionHandler: @escaping(( _ finshed: Bool) -> Void)){
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
                            self.nameOfDestination = location.name!
                            self.getDirections(to: location)
                            completionHandler(true)
                          //  self.delagateNavigation()
            }
        }
    func getLoactionTask(withCompletionHandler completionHandler: @escaping((_ location: String, _ finshed: Bool) -> Void)){
            self.userIsSpeaking { (location, finished) in
                if finished{
                    print("end reocrding")
                    completionHandler(location,true)
                }
            else{
             //   DispatchQueue.global(qos: .background).async{
                  //  self.vc.startSpeaking(messaage: "Where would you like to go?")
                  //  print("Where would you like to go?")
            //    }
                    completionHandler("",false)
            }
           
        }
    }
    func questionconfirmLoactioTask(location: String){
            
            print("confirming location...")
            vc.startSpeaking(messaage: "You would like to go to \(location), is that correct?")
        }
    func responseLocationConfirmation(location: String,withCompletionHandler completionHandler: @escaping((_ response: String, _ finshed: Bool) -> Void)){
        var confirmed = "nil"
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
                }
                else{
                    self.vc.startSpeaking(messaage: "Pleas answer with a yes or no")
                    print("Pleas answer with a yes or no")
                    //self.questionconfirmLoactioTask(location: location)
                    completionHandler( "unkwon", false)
            }
        }
                
            else{
                print("started listening")
            }
        }
    }
    func delagateNavigation(){

        DispatchQueue.main.async {
                self.delay(7){
                if object != "nil" && objPosition != "nil"{
                    self.vc.startSpeaking(messaage: "Careful!, there is a \(object),\(objPosition) ")
                    //if !self.running{self.delagateNavigation()}
            }
                
        }
    }
}
    func findCurrentLocation(completionHandler: @escaping (CLPlacemark?,_ success:Bool)
                         -> Void ) {
             // Use the last reported location.
            if let lastLocation = currentLocation{
                 let geocoder = CLGeocoder()
                     
                 // Look up the location and pass it to the completion handler
                geocoder.reverseGeocodeLocation(lastLocation,
                             completionHandler: { (placemarks, error) in
                     if error == nil {
                         let firstLocation = placemarks?[0]
                        completionHandler(firstLocation, true)
                     }
                     else {
                      // An error occurred during geocoding.
                         completionHandler(nil, false)
                     }
                 })
             }
             else {
                 // No location was available.
                 completionHandler(nil, false)
             }
         }
    @IBAction func tapTwice(_ sender: Any) {
                  print("works")
            findCurrentLocation { (location,success) in
                if success == true{
                    self.vc.startSpeaking(messaage: " you are currently in, \(location?.name ?? "notFound"),and the postal code is, \(location?.postalCode ?? "notFound")")
                    
                }
            }
    }
    @IBAction func firstResponder(_ sender: Any) {
        if tasksSequence[0] == 1{
             tasksSequence[0] = 0
            vc.startSpeaking(messaage: "Where would you like to go")
                 tasksSequence[1] = 1
             return
         }
            //get location
        else if tasksSequence[1] == 1{
                if tapCount < 2{
                    self.getLoactionTask { (location, finished) in
                        if finished{
                            self.desiredlocation = location
                            return
                        }
                    }
                    //go to next task
                    if tapCount == 1 {
                        tasksSequence[1] = 0
                        tasksSequence[2] = 1
                        tapCount = 0
                        return
                        }
                    else{
                        self.tapCount =  self.tapCount + 1
                            return
                    }
                }
            }
            //answer to confirm location
            else if tasksSequence[2] == 1{
                 tasksSequence[2] = 0
                 questionconfirmLoactioTask(location: desiredlocation)
                     tasksSequence[3] = 1
                 return
             }
            //responce to confirm location
            else if tasksSequence[3] == 1{
                    if tapCount1 < 2{
                            self.responseLocationConfirmation(location: desiredlocation) { (response, finished) in
                                if response == "Yes"{
                                    self.searchLocation(location: self.desiredlocation)
                                    { (completed) in
                                        if completed{
                                            self.running = false
                                            
                                        }
                                    }
                                }
                                else if response == "No"{
                                    self.desiredlocation = ""
                                    self.tasksSequence[0] = 1
                                    self.tasksSequence[3] = 0
                                    self.tapCount1 = 0
                                    return
                                }
                                else if response == "unkwon" {
                                    self.tasksSequence[2] = 1
                                    self.tasksSequence[3] = 0
                                }
                        }
                    if tapCount1 == 1{
                        tasksSequence[3] = 0
                        tasksSequence[4] = 1
                        tapCount1 = 0
                        return
                    }
                    else{
                        tapCount1 = tapCount1 + 1
                        return
                    }
            }
            
        }
            else if tasksSequence[4] == 1{
                
            }
            
        }
    }
        
    //get User current location
    extension MViewController: CLLocationManagerDelegate{
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
          //  manager.stopUpdatingLocation()
            //manager.startUpdatingLocation()
            guard let currLocation = locations.first else {return}
            currentCoordinate = currLocation.coordinate
            currentLocation = currLocation
           // print("my location is \(currentCoordinate)")
           // lblDirection.text = String(currLocation)
            mapView.userTrackingMode = .followWithHeading
            if !running{
                self.delay(10){
                   // DispatchQueue.main.asyncAfter(deadline: .now() + 7){
                    self.delagateNavigation()//}
                    //self.simulateNavigation()
                }
            }
        }
        func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
           
            if region is CLCircularRegion{
                if !running{
                print("in region \(count)")
                   // lblDirection.text = "in region \(count)"
                          if count < self.eachStep.count{
                           self.vc.startSpeaking(messaage: "proceed  straight for \(self.eachStep[self.count].distance) meters \(self.eachStep[self.count].instructions)")
                              print("proceeed for \(eachStep[count].distance) \(eachStep[count].instructions)")
                            self.count += 1
                          }
                          else {
                            self.vc.startSpeaking(messaage: "Arrived at destination")
                            giveSeconfIns = true
                }
            }
        }
    }
        func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        //self.stepsCount += 1
        if region is CLCircularRegion{
            lblDirection.text = "exited region \(count)"
             if giveSeconfIns{
                if count < self.eachStep.count-1{
            print("eixtet  region")
                      vc.startSpeaking(messaage: "exited region")
                   //   self.vc.startSpeaking(messaage: "procced  straight for \(self.eachStep[self.count+1].distance) //\(self.eachStep[self.count+1].instructions)")
                }
            }
            }
        }
    }
    extension MViewController: MKMapViewDelegate{
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline{
                let render = MKPolylineRenderer(overlay: overlay)
                render.lineWidth = 5
                render.strokeColor = .blue
                return render
            }
            
            if overlay is MKCircle{
                let circleRenderer = MKCircleRenderer(overlay: overlay)
                circleRenderer.alpha = 0.2
                circleRenderer.fillColor = .red
                circleRenderer.strokeColor = .orange
                return circleRenderer
            }
            return MKOverlayRenderer()
        }
    }

   
