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


class MVVControllerViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var lblDirection: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManger = CLLocationManager()
    var currentCoordinate: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManger.requestAlwaysAuthorization()
        locationManger.delegate = self
        locationManger.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManger.startUpdatingLocation()

    }
    func getDirections(to destionation: MKMapItem){
        let sourceMark = MKPlacemark(coordinate: currentCoordinate)
        let sourceDirection = MKMapItem(placemark: sourceMark)
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceDirection
        directionRequest.transportType = .walking
        
        let direction = MKDirections(request: directionRequest)
        direction.calculate { (response, _) in
            guard let response = response else { return }
            guard let mainPath = response.routes.first  else{return}
            
            self.mapView.addOverlay(mainPath.polyline)
            
        }

    }
}
//get User current location 
extension MVVControllerViewController: CLLocationManagerDelegate{
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        guard let currLocation = locations.first else {return}
        currentCoordinate = currLocation.coordinate
        mapView.userTrackingMode = .followWithHeading
    }
    
    
}
//Search location
extension MVVControllerViewController: UISearchBarDelegate{
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
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
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline{
            let render = MKPolylineRenderer(overlay: overlay)
            render.lineWidth = 13
            render.strokeColor = .blue
            return render
            
        }
        return MKOverlayRenderer()
        
    }
}
