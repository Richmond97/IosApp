//
//  mapsViewController.swift
//  Prototype2
//
//  Created by Richmond Yeboah on 31/01/2020.
//  Copyright © 2020 Richmond Yeboah. All rights reserved.
//

import UIKit
import GoogleMaps
import Direction
import CoreLocation
import Foundation

class mapsViewController: UIViewController,CLLocationManagerDelegate{


    @IBOutlet var mapView: GMSMapView!
    var locationManager = CLLocationManager()
    var didFindMyLocation = true
    var mapOps = MapsOps()
    // @IBOutlet var mapView: GMSMapView!
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if didFindMyLocation {
            let myLocation: CLLocation = change?[NSKeyValueChangeKey.newKey] as! CLLocation
            mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 10.0)
            mapView.settings.myLocationButton = true
            didFindMyLocation = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
         //let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 48.857165, longitude: 2.354613, zoom: 8.0)
         //let mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
        
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.new, context: nil)
        view = mapView
        //view.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.new, context: nil)
        //self.view.addSubview(mapView)
        
    }
    

    //Setting start location as user current location
    public func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            mapView.isMyLocationEnabled = true
        }

    
    }
    
}

