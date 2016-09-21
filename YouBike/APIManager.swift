//
//  API_Call.swift
//  YouBike
//
//  Created by Ka Ho on 7/5/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CoreLocation

class APIManager {
    
    private var currentLocation:CLLocationCoordinate2D!
    
    let distict:[String:String] = [
        "taipei" : "台北市",
        "newTaipei" : "新北市",
        "taoyuan" : "桃園市",
        "taichung" : "台中市"
    ]
    let apiCallIdentifier: [String:String] = [
        "taipei" : "http://data.taipei/youbike",
        "newTaipei" : "http://data.ntpc.gov.tw/od/data/api/54DDDC93-589C-4858-9C95-18B2046CC1FC?$format=json",
        "taoyuan" : "http://data.tycg.gov.tw/api/v1/rest/datastore/a1b4714b-3b75-4ff8-a8f2-cc377e4eaa0f?format=json",
        "taichung" : "http://ybjson01.youbike.com.tw:1002/gwjs.json"
    ]
    
    func distanceMeasure(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Int {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return Int(fromLocation.distanceFromLocation(toLocation))
    }
    
    private func parseJSONArray2object(callIdentifier: String, data: JSON) -> [StopInfo] {
        var result:[StopInfo] = []
        func parseJSONobject(each:JSON) -> StopInfo {
            let stopName = each["sna"].stringValue
            let availableBike = Int(each["sbi"].stringValue)!
            let availableSlot = Int(each["bemp"].stringValue)!
            let location = CLLocationCoordinate2D(latitude: Double(each["lat"].stringValue)!, longitude: Double(each["lng"].stringValue)!)
            let distance = distanceMeasure(currentLocation, to: location)
            return StopInfo(StopName: stopName, AvailableBike: availableBike, AvailableSlot: availableSlot, Coordinate: location, DistanceFromYou: distance)
        }
        if callIdentifier == "taipei" || callIdentifier == "taichung" {
            for (_, subJson) in data["retVal"] {
                result.append(parseJSONobject(subJson))
            }
        } else if callIdentifier ==  "newTaipei" {
            for subJson in data.arrayValue {
                result.append(parseJSONobject(subJson))
            }
        } else if callIdentifier == "taoyuan" {
            for subJson in data["result"]["records"].arrayValue {
                result.append(parseJSONobject(subJson))
            }
        }
        return result
    }
    
    func setCurrentLocation(location:CLLocationCoordinate2D) {
        currentLocation = location
    }
    
    func getAllStopInfo (completion: (result:[StopInfo], failedDistrict:[String]) -> Void) {
        var result:[StopInfo] = []
        var failed:[String] = []
        var resultCount:Int = 0
        for (key, value) in apiCallIdentifier {
            Alamofire.request(.GET, value).responseJSON { (response) in
                if let answer = response.result.value {
                    result += self.parseJSONArray2object(key, data: JSON(answer))
                } else {
                    failed.append(self.distict[key]!)
                }
                resultCount += 1
                if resultCount == self.apiCallIdentifier.count {completion(result: result, failedDistrict: failed)}
            }
        }
    }
    
}
