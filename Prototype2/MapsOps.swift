//
//  MapsOps.swift
//  Prototype2
//
//  Created by Richmond Yeboah on 22/04/2020.
//  Copyright © 2020 Richmond Yeboah. All rights reserved.
//

import UIKit
import Direction
import GoogleMaps

class MapsOps: NSObject {
    //used to request geocoding
    let URLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
    let key = "AIzaSyCE33AmZc7fNrlBFPsmq0OgElHkRDfPt7Y"
    //store the data of the first address that will be returned in the results, one or more
    var AddressResults: Dictionary<AnyHashable, AnyObject>!
    //store the values that their names suggest
    var fetchedAdrFormatted: String!
    //store the values that their names suggest
    var fetchedAdrLongitude: Double!
    //store the values that their names suggest
    var fetchedAdrLatitude: Double!
    
    //used to request direction from the direction API
    let URLDirections = "https://maps.googleapis.com/maps/api/directions/json?"
    //tore the first route (among the total number of routes) that will be returned from the Directions API
    var selectedRoute: Dictionary<AnyHashable, AnyObject>!
    //hold the overview polyline dictionary, which contains another dictionary with the points of the line to be displayed
    var overviewPolyline: Dictionary<AnyHashable, AnyObject>!
    //LLocationCoordinate2D objects that represent the longitude and latitude of the origin
    var originCor: CLLocationCoordinate2D!
    //LLocationCoordinate2D objects that represent the longitude and latitude of the destination
    var destinationCor: CLLocationCoordinate2D!
    //holds the origin n addresses as string values as in the APIs response.
    var originAdr: String!
    //hold the  destination as string values as in the APIs response.
    var destinationAddress: String!
    
    var totDistanceInMet: UInt = 0
    var totDistance: String!
    var totDurationInSec: UInt = 0
    var totDuration: String!
    
    override init() {
        super.init()
    }
    
    func geocodeAdr(address: String!, withCompletionHandler completionHandler: @escaping((_ status: String, _ success: Bool) -> Void)) {
        
        var dictionary = Dictionary<AnyHashable, AnyObject>()
        if let lookupAddress = address {
            var error : NSError?
            //let allowed = NSMutableCharacterSet.alphanumeric()
            var geocodeURLString = URLGeocode + "adßdress=" + lookupAddress + "&key=" + key
            print( "geocode url is = "+geocodeURLString)
            
            //ecode url
            geocodeURLString = ((geocodeURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))!)
            let geocodeURL = NSURL(string: geocodeURLString)
           DispatchQueue.global(qos: .background).async {
            do{
                var error_ : NSError?
                let geocodingResultsData = NSData(contentsOf: geocodeURL! as URL)
                print(geocodingResultsData as Any)
                dictionary = try JSONSerialization.jsonObject(with: geocodingResultsData! as Data, options:JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, AnyObject>
                error = error_
            }
            catch {
                print("JSONSerialization error:", error)
                
                }
            DispatchQueue.main.async {
                
                if (error != nil) {
                     print(error!)
                    completionHandler("", false)
                 }
                 
                else {
                     let status = dictionary["status"]
                 
                     if status as? String == "OK" {
                        //var results: NSObject = "results" as NSObject
                        let allResults = dictionary["results"] as? Array<Dictionary<AnyHashable, AnyObject>>
                        self.AddressResults = (allResults?[0])
                     
                     self.fetchedAdrFormatted = self.AddressResults["formatted_address"] as? String
                     let geometry = self.AddressResults!["geometry"] as! Dictionary<String, AnyObject>
                        self.fetchedAdrLongitude = ((geometry["location"] as! Dictionary<String, AnyObject>)["lng"] as! NSNumber).doubleValue
                        self.fetchedAdrLatitude = ((geometry["location"] as! Dictionary<String, AnyObject>)["lat"] as! NSNumber).doubleValue
                 
                        completionHandler("", true)
                    }
                    else {
                        completionHandler("", false)
                    }
                }
                
            }
    }
            
        }
        else {
            completionHandler("No valid address.", false)
        }
    }
    func getDirections(origin: String!, destination: String!, waypoints: Array<String>!, travelMode: AnyObject!, completionHandler: @escaping((_ status: String, _ success: Bool) -> Void)) {
        
        if let originLocation = origin {
                if let destinationLocation = destination {
                    var directionsURLString = URLDirections + "origin=" + originLocation + "&destination=" + destinationLocation + "&key=" + key
                    directionsURLString = directionsURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                    let directionsURL = NSURL(string: directionsURLString)
                   /*
                    Alamofire.request(directionsURLString).responseJSON
                        { response in

                            if let JSON = response.result.value {

                                let mapResponse: [String: AnyObject] = JSON as! [String : AnyObject]

                                let routesArray = (mapResponse["routes"] as? Array) ?? []

                                let routes = (routesArray.first as? Dictionary<String, AnyObject>) ?? [:]

                                let overviewPolyline = (routes["overview_polyline"] as? Dictionary<String,AnyObject>) ?? [:]
                                let polypoints = (overviewPolyline["points"] as? String) ?? ""
                                let line  = polypoints

                               // self.addPolyLine(encodedString: line)
                        }
                    }*/
                    
                   DispatchQueue.global(qos: .background).async {
                        
                    DispatchQueue.main.async {
                        
                        let directionsData = NSData(contentsOf: directionsURL! as URL)
                        
                           var error: NSError?
                        let dictionary: Dictionary<String, AnyObject> = try! JSONSerialization.jsonObject(with: directionsData! as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, AnyObject>
                        
                           if (error != nil) {
                               print(error)
                               completionHandler("",false)
                           }
                           else {
                            
                            let status = dictionary["status"] as! String
                             
                            if status == "OK" {
                                self.selectedRoute = (dictionary["routes"] as! Array<Dictionary<String, AnyObject>>)[0]
                                self.overviewPolyline = self.selectedRoute["overview_polyline"] as! Dictionary<String, AnyObject>
                             
                                let legs = self.selectedRoute["legs"] as! Array<Dictionary<String, AnyObject>>
                             
                                let startLocationDictionary = legs[0]["start_location"] as! Dictionary<String, AnyObject>
                                self.originCor = CLLocationCoordinate2DMake(startLocationDictionary["lat"] as! Double, startLocationDictionary["lng"] as! Double)
                             
                                let endLocationDictionary = legs[legs.count - 1]["end_location"] as! Dictionary<String, AnyObject>
                                self.destinationCor = CLLocationCoordinate2DMake(endLocationDictionary["lat"] as! Double, endLocationDictionary["lng"] as! Double)
                             
                                self.originAdr = legs[0]["start_address"] as! String
                                self.destinationAddress = legs[legs.count - 1]["end_address"] as! String
                             
                                self.calcTotDistAndDuration()
                             
                                completionHandler( status, true)
                            }
                            else {
                                completionHandler( status, false)
                            }
                        
                           }
                        
                         }
                    }
                }
                else {
                    completionHandler("Destination is empty.", false)
                }
            }
            else {
                completionHandler("Origin is empty", false)
            }
        
    }
    func calcTotDistAndDuration() {
        let legs = self.selectedRoute["legs"] as! Array<Dictionary<String, AnyObject>>
     
        totDistanceInMet = 0
        totDurationInSec = 0
        for leg in legs {
            totDistanceInMet += (leg["distance"] as! Dictionary<String, AnyObject>)["value"] as! UInt
            totDurationInSec += (leg["duration"] as! Dictionary<String, AnyObject>)["value"] as! UInt
        }
        let distanceInKilometers: Double = Double(totDistanceInMet / 1000)
        totDistance = "Total Distance: \(distanceInKilometers) Km"
     
        let mins = totDurationInSec / 60
        let hours = mins / 60
        let days = hours / 24
        let hoursLeft = hours % 24
        let minutesLeft = mins % 60
        let SecsLeft = totDurationInSec % 60
     
        totDuration = "Duration: \(days) d, \(hoursLeft) h, \(minutesLeft) mins, \(SecsLeft) secs"
    }

}
