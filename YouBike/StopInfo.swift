//
//  StopInfo.swift
//  YouBike
//
//  Created by Ka Ho on 18/9/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import Foundation
import CoreLocation

class StopInfo {
    
    var stopName:String!
    var availableBike:Int!
    var availableSlot:Int!
    var coordinate:CLLocationCoordinate2D!
    var distanceFromYou:Int!
    
    init(StopName:String, AvailableBike:Int, AvailableSlot:Int, Coordinate:CLLocationCoordinate2D, DistanceFromYou:Int) {
        stopName = StopName
        availableBike = AvailableBike
        availableSlot = AvailableSlot
        coordinate = Coordinate
        distanceFromYou = DistanceFromYou
    }

}