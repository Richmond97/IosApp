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

//the detected object are assigned to this vars,
//from the objectDetection class
var object: String = "nil"
var objPosition: String = "nil"

class MViewController: UIViewController {

         @IBOutlet weak var lblSteps: UILabel!
         @IBOutlet weak var tapGesture: UIButton!
         @IBOutlet weak var lblTitle: UILabel!
         @IBOutlet weak var lblDirection: UILabel!
         @IBOutlet weak var mapView: MKMapView!
    
         let vc = SpeechSynthetizer()

         var eachStep = [MKRoute.Step]()
         let speachSynthesizer = AVSpeechSynthesizer()
         let locationManger = CLLocationManager()
         var currentCoordinate: CLLocationCoordinate2D!
         var currentLocation: CLLocation!
         var mradius :MKCircle!
         var turnRegion:CLCircularRegion!
         var mainPath:MKRoute!
    
         var instructions: String = "nil"
         var tasksSequence: Array = [1,0,0,0,0,0]
         var expectedTravelTime: TimeInterval = 0
    
         //location info
         var desiredlocation = "nil"
         var venueName = "unknown"
         //bool
         var running = true
         var startSimulation = false
         var giveSeconfIns = false
         //count needed outside of methods
         var count = 0
         var i = 1
         var tapCount = 0
         var simulationCount = 0
    
         override func viewDidLoad() {
             
             locationManger.requestAlwaysAuthorization()
             locationManger.delegate = self
             locationManger.desiredAccuracy = 0.02
             locationManger.activityType = .fitness
             locationManger.startUpdatingLocation()
             locationManger.allowsBackgroundLocationUpdates = true
             locationManger.distanceFilter = -0.02
             locationManger.pausesLocationUpdatesAutomatically = false
            
             super.viewDidLoad()
         }
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    func alertStartingJourney(){
            
            self.vc.startSpeaking(messaage: "Ok let's begin, I am taking you to  \(self.venueName), and will roughly take about \(Int(self.expectedTravelTime)) minutes",type: "indication")
        }
    func userIsSpeaking(withCompletionHandler completionHandler: @escaping((_ instruction: String, _ finshed: Bool) -> Void)){
            if  vc.audioEngine.isRunning{
                lblTitle.text = "STOPED"
                vc.audioEngine.stop()
                vc.recognitionReq?.endAudio()
            }else{
                lblTitle.text = "RECORDING..."
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
    // completion handler returns true only if the
    //duration of the jounery is pf walkable distance
    func getDirections(to userDestination: MKMapItem,withCompletionHandler completionHandler: @escaping(( _ success: Bool) -> Void)){
        let sourceMark = MKPlacemark(coordinate: currentCoordinate)
        let source = MKMapItem(placemark: sourceMark)
        let directionsReq = MKDirections.Request()
        directionsReq.source = source
        directionsReq.destination = userDestination
        directionsReq.transportType = .walking
        let directions = MKDirections(request: directionsReq)
        directions.calculate { (response, error) in
            guard let response = response else { return }
            self.mainPath = response.routes.first
            self.expectedTravelTime =  self.mainPath.expectedTravelTime
            self.expectedTravelTime = self.expectedTravelTime / 60
            
            
            //checking the duration of the jouney
            if self.expectedTravelTime > 35{
                completionHandler(false)
            }
            else{
            self.mapView.addOverlay(self.mainPath.polyline)
            
            //stop monitoring regions that has been already entered
            self.locationManger.monitoredRegions.forEach({ self.locationManger.stopMonitoring(for: $0) })
            
            self.eachStep = self.mainPath.steps
            for i in 0 ..< self.eachStep.count {
                
                let nextStep = self.mainPath.steps[i]
                print(nextStep.instructions)
                print(nextStep.distance)
                print(nextStep.notice ??  "there is no warning")

                self.turnRegion = CLCircularRegion(center: nextStep.polyline.coordinate,
                                            radius: 20,
                                            identifier: "\(i)")
                //monitor regions
                self.locationManger.startMonitoring(for: self.turnRegion)
                
                //display region on map
                self.mradius = MKCircle(center: self.turnRegion.center, radius: self.turnRegion.radius)
                self.mapView.addOverlay(self.mradius)

            }
            self.alertStartingJourney()
            completionHandler(true)
        }
        }
    }
    func clearMap(){
        for layers in mapView.overlays {
              self.mapView.removeOverlay(layers)
         }
    }
    //search location and use the obtainesd coordinates in getDirections()
    func searchLocation(location:String,withCompletionHandler completionHandler: @escaping(( _ finshed: Bool) -> Void)){
            let searchReq = MKLocalSearch.Request()
                        searchReq.naturalLanguageQuery = location
                        let region = MKCoordinateRegion(center:currentCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.1
                            , longitudeDelta: 0.1))
                        searchReq.region = region
                        let closestSearch = MKLocalSearch(request: searchReq)
                        closestSearch.start { (response, _) in
                            guard let response = response else {return}
                            print(response.mapItems.first!)
                            //grab first item
                            guard let location = response.mapItems.first else{return}
                            self.venueName = location.name!
                            self.getDirections(to: location)
                            { (success) in
                                if success{
                                    completionHandler(true)
                                }
                                else{
                                    completionHandler(false)
                                }
                            
            }
        }
    }
    //listen to user locrion
    func getLoactionTask(withCompletionHandler completionHandler: @escaping((_ location: String, _ finshed: Bool) -> Void)){
            self.userIsSpeaking { (location, finished) in
                if finished{
                    print("end reocrding")
                    completionHandler(location,true)
                }
            else{
                    completionHandler("",false)
            }
           
        }
    }
    //listen to user answer
    func confirmAction(location: String){
            
            print("confirming location...")
            vc.startSpeaking(messaage: "You would like to go to \(location), is that correct?",type: "indication")
        }
    
    //managing user response YES,NO.UNKNOWN
    func responseConfirmation(location: String,type: String, withCompletionHandler completionHandler: @escaping((_ response: String, _ finshed: Bool) -> Void)){
        self.userIsSpeaking { (answer, finished) in
            if finished {
                if answer == "Yes"{
                    if type == "newJourney"{
                        self.vc.startSpeaking(messaage: "Ok, you can now start a new journey",type: "indication")
                        completionHandler( answer, false)}
                    else{
                        completionHandler( answer, true)}
                }
                else if answer == "No"{
                    if type == "newJourney"{
                        self.vc.startSpeaking(messaage: "Ok, i am taking you back your current navigation",type: "indication")
                        completionHandler( answer, false)
                    }
                    else{
                        self.vc.startSpeaking(messaage: "Sorry, I didn't get that",type: "indication")
                        completionHandler( answer, false)
                    }
                }
                else{
                    self.vc.startSpeaking(messaage: "Pleas answer with a yes or no",type: "indication")
                    print("Pleas answer with a yes or no")
                    completionHandler( "unkwon", false)
            }
        }
                
            else{
                print("started listening")
            }
        }
    }
    
    //detect objects during navigation
    func delagateNavigation(){
        DispatchQueue.main.async {
               self.delay(5){
                if object != "nil" && objPosition != "nil"{
                   if !self.vc.synthetizer.isSpeaking{
                         self.vc.startSpeaking(messaage: "Careful!, there is a \(object),\(objPosition) ", type: "obj")
                    }else{}
                }
                else{}
            }
    }
}
    
    //return user current location
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
                 // No location was found.
                 completionHandler(nil, false)
             }
         }
    
    //Test Navigation
    @IBAction func simulateNavigation(_ sender: Any) {
        if startSimulation {
            lblDirection.text = "IN NAVIGATION..."
             print(i)
             print(self.eachStep.count)
                if i < self.eachStep.count {
                    if self.simulationCount == 0 {
                        DispatchQueue.main.async(){ self.vc.startSpeaking(messaage: "Proceed  straight for \(self.eachStep[self.i].distance) meters",type: "indication")
                        self.lblSteps.text = "Proceed  straight for \(self.eachStep[self.i].distance) meters"
                        self.simulationCount = 1
                        
                            return
                        }
                    }
                    else{
                        
                        DispatchQueue.main.async(){ self.vc.startSpeaking(messaage: "Now \(self.eachStep[self.i].instructions)",type: "indication")
                            self.lblSteps.text = "Now \(self.eachStep[self.i].instructions)"
                            self.i += 1
                            self.simulationCount = 0
                            
                        }
                    }
                }
                else{
                    DispatchQueue.main.async(){
                    self.vc.startSpeaking(messaage: "Arrived at destination", type: "indication")
                    }
                }
            }
    }
    @IBAction func tapTwice(_ sender: Any) {
            //print("works")
            findCurrentLocation { (location,success) in
                if success == true{
                    self.vc.startSpeaking(messaage: " you are currently in, \(location?.name ?? "notFound"),and the postal code is, \(location?.postalCode ?? "notFound")",type: "indication")
                    
                }
            }
    }
    @IBAction func firstResponder(_ sender: Any) {
        if tasksSequence[0] == 1{
             tasksSequence[0] = 0
            vc.startSpeaking(messaage: "Where would you like to go",type: "indication")
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
                confirmAction(location: desiredlocation)
                    tasksSequence[3] = 1
                return
            }
            //responce to confirm location
        else if tasksSequence[3] == 1{
                if tapCount < 2{
                    self.responseConfirmation(location: desiredlocation, type:"nil") { (response, finished) in
                            if response == "Yes"{
                                    self.searchLocation(location: self.desiredlocation)
                                    { (succcess) in
                                    if !succcess{
                                        //if false is returned from searcLocation it means that the duration of the journey is too long (>35min)
                                        print("Travel time: \(self.expectedTravelTime) minutes ")
                                            self.vc.startSpeaking(messaage: "Sorry \(Int(self.expectedTravelTime)) minutes, is not a walkable distance, please choose a closer destination",type: "indication")
                                            self.desiredlocation = ""
                                            self.tasksSequence[0] = 1
                                            self.tasksSequence[3] = 0
                                            self.tapCount = 0
                                            return
                                    }
                                    else{
                                        self.running = false
                                        self.startSimulation = true
                                            self.delagateNavigation()
                                            }
                                    }
                                }
                            else if response == "No"{
                                self.desiredlocation = ""
                                self.tasksSequence[0] = 1
                                self.tasksSequence[3] = 0
                                self.tapCount = 0
                                return
                            }
                            else if response == "unkwon" {
                                self.tasksSequence[2] = 1
                                self.tasksSequence[3] = 0
                                self.tapCount = 0
                                return
                            }
                    }
                if tapCount == 1{
                    tasksSequence[3] = 0
                    tasksSequence[4] = 1
                    tapCount = 0
                    return
                }
                else{
                    tapCount = tapCount + 1
                    return
                }
        }
        
    }
            //When user taps the screen duinng naviagtion
        else if tasksSequence[4] == 1{
            self.vc.startSpeaking(messaage: " Would you like to start a new journey?", type: "indication")
            self.tasksSequence[4] = 0
            self.tasksSequence[5] = 1
            return
        }
            //resoonse to exit navigation
        else if tasksSequence[5] == 1{
            if tapCount < 2{
                self.responseConfirmation(location: "exit navigattion", type:"newJourney") { (answer, finished) in
                                if answer == "Yes"{
                                    self.running = false
                                    self.clearMap()
                                    self.tasksSequence[0] = 1
                                    self.tasksSequence[5] = 0
                                }
                                else if answer == "No"{
                                    self.tasksSequence[4] = 1
                                    self.tapCount = 0
                                    return
                                }
                                else if answer == "unkwon" {
                                    self.tasksSequence[4] = 1
                                    self.tasksSequence[5] = 0
                                    self.tapCount = 0
                                    return
                                }
                        }
                    if tapCount == 1{
                        tapCount = 0
                        return
                    }
                    else{
                        tapCount = tapCount + 1
                        return
                    }
            }
            
        }
    }
}
    //get user coordinates
    extension MViewController: CLLocationManagerDelegate{
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let currLocation = locations.first else {return}
            currentCoordinate = currLocation.coordinate
            currentLocation = currLocation
            mapView.userTrackingMode = .followWithHeading
           if !running{
                self.delay(10){
                   DispatchQueue.main.async(){
                    self.delagateNavigation()}
                }
            }
        }
        func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
           //When user enters in region
           if region is CLCircularRegion{
                lblDirection.text = "IN NAVIGATION..."
                self.count += 1
                if !running{
                lblDirection.text = "in region \(count)"
                    lblSteps.text = " \(self.eachStep[self.count].instructions), then, proceed  straight for \(self.eachStep[self.count].distance) meters"
                          if count < self.eachStep.count{
                           DispatchQueue.main.async(){ self.vc.startSpeaking(messaage: " \(self.eachStep[self.count].instructions), then, proceed  straight for \(self.eachStep[self.count].distance) meters",type: "indication")
                            }
                              print("proceeed for \(eachStep[count].distance) \(eachStep[count].instructions)")
                              giveSeconfIns = true
                          }
                          else {
                             DispatchQueue.main.async(){
                            self.vc.startSpeaking(messaage: "Arrived at destination", type: "indication")
                            }
                            giveSeconfIns = false
                }
                     
            }
        }
    }
        //directions to the user when he exits a region
        func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
            if region is CLCircularRegion{
                if giveSeconfIns{
                    if count < self.eachStep.count-1{
                        //print("eixted region")
                        findCurrentLocation { (location,success) in
                            if success == true{
                                self.vc.startSpeaking(messaage: " Proceed on, \(location?.name ?? "  ")",type: "indication")
                                
                            }
                            
                        }
                        
                    }
                    
                }
            }
        }
    }

    //add overlay
    extension MViewController: MKMapViewDelegate{
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            //draw route on map
            if overlay is MKPolyline{
                let render = MKPolylineRenderer(overlay: overlay)
                render.lineWidth = 5
                render.strokeColor = .blue
                return render
            }
            //draw region on map
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



//Reference
//******************************************************************************************************************************************************/
/*    Title:Converting Between Coordinates and User-Friendly Place Names
 *    Author: Copyright © 2020 Apple Inc. All rights reserved.
 *    Date: 04/21/2020
 *    Code version: 1.0
 *    Availability: https://developer.apple.com/documentation/corelocation/converting_between_coordinates_and_user-friendly_place_names
 *
*******************************************************************************************************************************************************/

