//
//  API_Call.swift
//  YouBike
//
//  Created by Ka Ho on 7/5/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import Foundation
import Alamofire

let taipeiYoubikeAPI_url = "http://data.taipei/youbike"
let newtaipeiYoubikeAPI_url = "http://data.ntpc.gov.tw/od/data/api/54DDDC93-589C-4858-9C95-18B2046CC1FC?$format=json"

func dataTaipeiYouBikeAPICall (completion: (taipeiResult: AnyObject) -> Void) {
    Alamofire.request(.GET, taipeiYoubikeAPI_url).responseJSON { (response) in
        completion(taipeiResult: response.result.value!)
    }
}

func newTaipeiYouBikeAPICall (completion: (newtaipeiResult: AnyObject) -> Void) {
    Alamofire.request(.GET, newtaipeiYoubikeAPI_url).responseJSON { (response) in
        completion(newtaipeiResult: response.result.value!)
    }
}