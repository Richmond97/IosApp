//
//  MVVControllerViewController.swift
//  Prototype2
//
//  Created by Richmond Yeboah on 26/04/2020.
//  Copyright © 2020 Richmond Yeboah. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation


class MVVControllerViewController: UIViewController {

    @IBOutlet weak var voiceActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var lblDirection: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    var eachStep = [MKRoute.Step]()
    let speachSynthesizer = AVSpeechSynthesizer()
    let locationManger = CLLocationManager()
    var currentCoordinate: CLLocationCoordinate2D!
    var stepsCount = 0
    var currStep = 0
    var tapCount = 0
    
    let voiceActivity = SpeechSynthetizer.startListening(SpeechSynthetizer)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManger.requestAlwaysAuthorization()
        locationManger.delegate = self
        locationManger.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManger.startUpdatingLocation()
        
    }
    @IBAction func tapGestureAction(_ sender: Any) {
        if tapCount == 1{
            voiceActivityIndicator.startAnimating()
           // voiceActivity.au
        }
        else{
            tapCount = 0
            voiceActivityIndicator.stopAnimating()
        }
        
    }
    
    func calculateNextMove(to nextTurn: MKRoute.Step) -> Array<Any>{
        var nextTurnInfo: Array<Any> = []
        let distance = nextTurn.distance
        let info = nextTurn.instructions
        nextTurnInfo.append(distance)
        nextTurnInfo.append(info)
        return nextTurnInfo
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
            
            self.locationManger.monitoredRegions.forEach({ self.locationManger.stopMonitoring(for: $0) })
            
            self.mapView.addOverlay(mainPath.polyline)
            self.eachStep = mainPath.steps
            
            for i in 0 ..< mainPath.steps.count {
                let  currStep = i
                
                let nextStep = mainPath.steps[i]
                print(nextStep.instructions)
                print(nextStep.distance)
               
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
                let distance = nextMove[0]
                let info = nextMove[0]
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
        mapView.userTrackingMode = .followWithHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    print("in region")
    stepsCount += 1
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
extension MVVControllerViewController: UISearchBarDelegate{
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
    }
}
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
