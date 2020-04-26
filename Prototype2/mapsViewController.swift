//
//  mapsViewController.swift
//  Prototype2
//
//  Created by Richmond Yeboah on 31/01/2020.
//  Copyright © 2020 Richmond Yeboah. All rights reserved.
//

/*import UIKit
import GoogleMaps
import Direction
import CoreLocation
import Foundation

class mapsViewController: UIViewController,CLLocationManagerDelegate{
    @IBOutlet weak var lblInfo: UILabel!
    @IBOutlet weak var findAddress: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    var mapOps = MapsOps()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 48.857165, longitude: 2.354613, zoom: 8.0)
       //mapView.camera = camera

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        


       // let myLocation: CLLocation = change?[NSKeyValueChangeKey.newKey] as! CLLocation
      //  self.mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 14.0)
        self.mapView.addObserver(self,forKeyPath: ("myLocation"),options: NSKeyValueObservingOptions.new, context:  nil)
         }
    
    override func didReceiveMemoryWarning()
     {
         super.didReceiveMemoryWarning()
     }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       if status == CLAuthorizationStatus.authorizedWhenInUse || status == .authorizedAlways {
        mapView.isMyLocationEnabled = true
        locationManager.stopUpdatingLocation()
       // mapView.userTrackingMode = .followWithHeading
        
       }
    }
    override func observeValue( forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if  didFindMyLocation {
                let myLocation: CLLocation = change?[NSKeyValueChangeKey.newKey] as! CLLocation
                self.mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 14.0)
                self.mapView.isMyLocationEnabled = true
                self.mapView.settings.myLocationButton = true
                self.didFindMyLocation = true
                print("my location is ", myLocation.coordinate)
            }
    }
    
    @IBAction func searchAction(_ sender: Any) {
      /*  let addressAlert = UIAlertController(title: "Address Finder", message: "Type the address you want to find:", preferredStyle: UIAlertController.Style.alert)
                
               addressAlert.addTextField { (textField) -> Void in
                       textField.placeholder = "Address?"
                   }
                
               let findAction = UIAlertAction(title: "Find Address", style: UIAlertAction.Style.default) { (alertAction) -> Void in
                   let address = (addressAlert.textFields![0] as UITextField).text as! String
                
                   self.mapOps.geocodeAdr(address: address, withCompletionHandler: { (status, success) -> Void in
                       
                       if !success {
                                      print(status)
                       
                                      if status == "ZERO_RESULTS" {
                                       
                                       self.showAlertWithMessage(message: "The location could not be found.")
                                      }
                                  }
                                  else {
                                      let coordinate = CLLocationCoordinate2D(latitude: self.mapOps.fetchedAdrLatitude, longitude: self.mapOps.fetchedAdrLongitude)
                           self.mapView.camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 14.0)
                        self.setuplocationPointer(coordinate: coordinate)
                                  }
                       })
                   }
               let closeAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel) { (alertAction) -> Void in
                   }
                   addressAlert.addAction(findAction)
                   addressAlert.addAction(closeAction)
               present(addressAlert, animated: true, completion: nil)
                */
        createRoute()//sender: AnyObject
                       
               }
    func showAlertWithMessage(message: String) {
    let alertController = UIAlertController(title: "GMapsDemo", message: message, preferredStyle: UIAlertController.Style.alert)
    let closeAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel) { (alertAction) -> Void in
           }
           alertController.addAction(closeAction)
           present(alertController, animated: true, completion: nil)
                
    }

    func setuplocationPointer(coordinate: CLLocationCoordinate2D) {
        var locationPointer: GMSMarker!
        locationPointer = GMSMarker(position: coordinate)
        locationPointer.map = mapView
        locationPointer.title = mapOps.fetchedAdrFormatted
        locationPointer.appearAnimation = GMSMarkerAnimation.pop
        locationPointer.icon = GMSMarker.markerImage(with: UIColor.blue)
        locationPointer.opacity = 0.75
    }
    func createRoute() {
        let addressAlert = UIAlertController(title: "Create Route", message: "Connect locations with a route:", preferredStyle: UIAlertController.Style.alert)
     
        addressAlert.addTextField { (textField) -> Void in
            textField.placeholder = "Origin?"
        }
     
        addressAlert.addTextField { (textField) -> Void in
            textField.placeholder = "Destination?"
        }
     
     
        let createRouteAction = UIAlertAction(title: "Create Route", style: UIAlertAction.Style.default) { (alertAction) -> Void in
            let origin = (addressAlert.textFields![0] as UITextField).text as! String
            let destination = (addressAlert.textFields![1] as UITextField).text as! String
     
            self.mapOps.getDirections(origin: origin, destination: destination, waypoints: nil, travelMode: nil, completionHandler: { (status, success) -> Void in
                if success {
                    self.setMapforRoute()
                    self.showRoute()
                    self.showRouteInfo()
                    print(status)
                }
                else {
                    print(status)
                }
            })
        }
     
        let closeAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel) { (alertAction) -> Void in
     
        }
     
        addressAlert.addAction(createRouteAction)
        addressAlert.addAction(closeAction)
     
        present(addressAlert, animated: true, completion: nil)
    }
    func setMapforRoute(){
        originMarker = GMSMarker(position: self.mapOps.originCor)
        originMarker.map = self.mapView
        originMarker.icon = GMSMarker.markerImage(with: UIColor.green)
        originMarker.title = self.mapOps.originAdr
         
        destinationMarker = GMSMarker(position: self.mapOps.destinationCor)
        destinationMarker.map = self.mapView
        destinationMarker.icon = GMSMarker.markerImage(with: UIColor.red)
        destinationMarker.title = self.mapOps.destinationAddress
    }
    func showRoute(){
        let route = mapOps.overviewPolyline["points"] as! String
        
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline = GMSPolyline(path: path)
        routePolyline.map = mapView!
    }
    func showRouteInfo(){
        lblInfo.text = mapOps.totDistance  + "\n" + mapOps.totDuration
    }
}
    
/*extension mapsViewController: CLLocationManagerDelegate
{
     //Setting start location as user current location
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse || status == .authorizedAlways {
             mapView.isMyLocationEnabled = true
             locationManager.stopUpdatingLocation()
         }
        else{
            mapView.isMyLocationEnabled = true
            locationManager.stopUpdatingLocation()
        }
     }
     
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
     {
         if locations.count > 0
         {
             mapView.camera = GMSCameraPosition.camera(withTarget: (locations.last?.coordinate)!, zoom: 0.2)
             mapView.settings.myLocationButton = true
         }
     }
}*/
*/
