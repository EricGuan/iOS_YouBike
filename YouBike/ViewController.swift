//
//  ViewController.swift
//  YouBike
//
//  Created by Ka Ho on 7/5/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation
import MapKit
import PKHUD

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var navigationMapView: MKMapView!
    @IBOutlet weak var bikeStoptableView: UITableView!
    @IBOutlet weak var distanceLeftLabel: UILabel!
    var destinationMarker = MKPointAnnotation()
    let locationManager = CLLocationManager()
    let distanceToUpdatelocation: Double = 100.0
    let timeToUpdateAPI: Double = 60
    var lastLocationInfo: CLLocation?
    var currentLocationInfo: CLLocation?
    var lastUpdatetime: NSDate?
    var initialStart: Bool = true
    var bikeInfoArray:[String:[String:String]] = [:]
    var sortedBikeInfo:[(String,[String:String])] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationMapView.alpha = 0
        bikeStoptableView.alpha = 0
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        navigationMapView.delegate = self
    }
    
    func youbikeAPICall(completion: (json: JSON) -> Void) {
        dataTaipeiYouBikeAPICall { (result) in
            completion(json: JSON(result))
        }
    }
    
    func youbikeJSONtoArray(jsonResult: JSON) {
        for (key, subJson) in jsonResult["retVal"] {
            let stopName = subJson["sna"].stringValue
            let availableBike = subJson["sbi"].stringValue
            let availableSlot = subJson["bemp"].stringValue
            let lat = subJson["lat"].stringValue
            let lng = subJson["lng"].stringValue
            if initialStart {
                self.bikeInfoArray[key] = ["stopName":stopName, "availableBike":availableBike, "availableSlot":availableSlot, "lat":lat, "lng":lng, "distanceFromYou":""]
            } else {
                self.bikeInfoArray[key]!["availableBike"] = availableBike
                self.bikeInfoArray[key]!["availableSlot"] = availableSlot
            }
        }
    }
    
    func sortArrayByDistance(sourceLocation: CLLocation) {
        for loop in bikeInfoArray {
            let stopLocation = CLLocation(latitude: Double(loop.1["lat"]!)!, longitude: Double(loop.1["lng"]!)!)
            bikeInfoArray[loop.0]!["distanceFromYou"] = String(stopLocation.distanceFromLocation(sourceLocation))
        }
        sortedBikeInfo = bikeInfoArray.sort({Double($0.1["distanceFromYou"]!)! < Double($1.1["distanceFromYou"]!)!})
    }
    
    func markDestinationStop(position: Int) {
        let lat = Double(sortedBikeInfo[position].1["lat"]!)!
        let lng = Double(sortedBikeInfo[position].1["lng"]!)!
        let stopName = sortedBikeInfo[position].1["stopName"]
        let availableBike = sortedBikeInfo[position].1["availableBike"]!
        let availableSlot = sortedBikeInfo[position].1["availableSlot"]!
        destinationMarker.title = "可借: \(availableBike) 可還: \(availableSlot)"
        destinationMarker.subtitle = stopName
        destinationMarker.coordinate = CLLocationCoordinate2DMake(lat, lng)
        navigationMapView.addAnnotation(destinationMarker)
        navigationToBikeStop(CLLocationCoordinate2DMake(lat, lng))
    }
    
    func navigationToBikeStop(stopLocation: CLLocationCoordinate2D) {
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocationInfo!.coordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: stopLocation, addressDictionary: nil))
        request.requestsAlternateRoutes = false
        request.transportType = .Walking
        
        let directions = MKDirections(request: request)
        
        directions.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
            for route in unwrappedResponse.routes {
                self.navigationMapView.removeOverlays(self.navigationMapView.overlays)
                self.navigationMapView.addOverlay(route.polyline)
                self.navigationMapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0), animated: true)
            }
        }
    }
    
    func updateDistanceLable() {
        distanceLeftLabel.text = "距離：\(Int(currentLocationInfo!.distanceFromLocation(CLLocation(latitude: destinationMarker.coordinate.latitude, longitude: destinationMarker.coordinate.longitude))))米"
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.4)
        renderer.lineWidth = 5.0
        return renderer
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocationInfo = locations[0]
        initialStart ? lastLocationInfo = currentLocationInfo : ()
        initialStart ? HUD.show(.LabeledProgress(title: "即時資料加載中", subtitle: "請稍候")) : ()
        initialStart ? () : updateDistanceLable()
        
        if initialStart || NSDate().compare(lastUpdatetime!.dateByAddingTimeInterval(timeToUpdateAPI)) == NSComparisonResult.OrderedDescending {
            lastUpdatetime = NSDate()
            youbikeAPICall { (json) in
                self.youbikeJSONtoArray(json)
                self.sortArrayByDistance(self.currentLocationInfo!)
                if self.initialStart {
                    self.markDestinationStop(0)
                    self.updateDistanceLable()
                    self.initialStart = false
                    self.navigationMapView.alpha = 1
                    self.bikeStoptableView.alpha = 1
                    HUD.hide()
                }
                self.bikeStoptableView.reloadData()
            }
        }

        if currentLocationInfo!.distanceFromLocation(lastLocationInfo!) > distanceToUpdatelocation {
            lastLocationInfo = currentLocationInfo
            sortArrayByDistance(currentLocationInfo!)
            bikeStoptableView.reloadData()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedBikeInfo.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("bikeStop_TableViewCell") as! bikeStop_TableViewCell
        cell.stopNameLabel.text = sortedBikeInfo[indexPath.row].1["stopName"]
        cell.availableBikeLabel.text = sortedBikeInfo[indexPath.row].1["availableBike"]
        cell.availableBikeLabel.backgroundColor = sortedBikeInfo[indexPath.row].1["availableBike"] == "0" ? UIColor.redColor() : UIColor(red: 0.004, green: 0.839, blue: 0.004, alpha: 1)
        cell.availableSlotLabel.text = sortedBikeInfo[indexPath.row].1["availableSlot"]
        cell.availableSlotLabel.backgroundColor = sortedBikeInfo[indexPath.row].1["availableSlot"] == "0" ? UIColor.redColor() : UIColor.orangeColor()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        markDestinationStop(indexPath.row)
        updateDistanceLable()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}