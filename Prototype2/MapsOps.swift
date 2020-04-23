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

class MapsOps: AnyObject {
    //used to request geocoding
    let URLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
    //store the data of the first address that will be returned in the results, one or more
    var AddressResults: Dictionary<NSObject, AnyObject>!
    //store the values that their names suggest
    var fetchedAdrFormatted: String!
    //store the values that their names suggest
    var fetchedAdrLongitude: Double!
    //store the values that their names suggest
    var fetchedAdrLatitude: Double!

    override init() {
        super.init()
    }
    
    func geocodeAdr(address: String!, withCompletionHandler completionHandler: ((_ status: String, _ success: Bool) -> Void)) {
        
        
        if let lookupAddress = address {
            var error : NSError?
            var dictionary : Dictionary<String, AnyObject>
            let allowed = NSMutableCharacterSet.alphanumeric()
            var geocodeURLString = URLGeocode + "address=" + lookupAddress
            geocodeURLString = ((geocodeURLString.addingPercentEncoding(withAllowedCharacters:allowed as CharacterSet))!)
            let geocodeURL = NSURL(string: geocodeURLString)
            
            //make a request to the geocoding API and store the returned results to a NSData object
            //done asynchronously to allow the application to be responsive
           DispatchQueue.global(qos: .background).async {
            do{
                let geocodingResultsData = NSData(contentsOf: geocodeURL! as URL)
                dictionary = try JSONSerialization.jsonObject(with: geocodingResultsData! as Data, options:JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, AnyObject>
              //  var dictionary: Dictionary<NSObject, AnyObject> = try JSONSerialization.jsonObject(with: geocodingResultsData! as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<NSObject, AnyObject>
              // dictionary = JsonConvert.DeserializeObject<Dictionary<NSObject, AnyObject>>(geocodingResultsData);
            }
            catch {
                print("JSONSerialization error:", error)
                
                }
            DispatchQueue.main.async {
                
            }
    }
            if (error != nil) {
                print(error)
                completionHandler( "", false)
            }
            
           else {
               // Get the response status.
               // var status_: NSObject = "status" as NSObject
                let status = dictionary["status"]!
            
                if status as! String == "OK" {
                   //var results: NSObject = "results" as NSObject
                   let allResults = dictionary["sresults"] as! Dictionary<NSObject, AnyObject>
                   self.AddressResults = allResults[0]
                
                   // Keep the most important values.
              //  var formatted_address: NSObject = "formatted_address" as NSObject
               // var geometry_: NSObject = "geometry" as NSObject
               // var location: NSObject = "location" as NSObject
                //var latitude: NSObject = "latitude" as NSObject
               // var lng: NSObject = "lng" as NSObject
               // var lat: NSObject = "lat" as NSObject
                self.fetchedAdrFormatted = self.AddressResults["formatted_address"] as? String
                let geometry = self.AddressResults!["geometry"] as! Dictionary<String, AnyObject>
                   self.fetchedAdrLongitude = ((geometry["location"] as! Dictionary<String, AnyObject>)["lng"] as! NSNumber).doubleValue
                   self.fetchedAdrLatitude = ((geometry["latitude"] as! Dictionary<String, AnyObject>)["lat"] as! NSNumber).doubleValue
            
                   completionHandler("", true)
               }
               else {
                   completionHandler("", false)
               }
           }
        }
        else {
            completionHandler("No valid address.", false)
        }
    }
}
