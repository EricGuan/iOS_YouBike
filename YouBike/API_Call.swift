//
//  API_Call.swift
//  YouBike
//
//  Created by Ka Ho on 7/5/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import Foundation
import Alamofire

let youbikeAPI_url = "http://data.taipei/youbike"

func dataTaipeiYouBikeAPICall (completion: (result: AnyObject) -> Void) {
    Alamofire.request(.GET, youbikeAPI_url).responseJSON { (response) in
        completion(result: response.result.value!)
    }
}