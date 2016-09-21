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
    @IBOutlet weak var headerTipsView: UIView!
    @IBOutlet weak var distanceLeftLabel: UILabel!
    var destinationMarker = MKPointAnnotation()
    let locationManager = CLLocationManager()
    let distanceToUpdatelocation: Double = 100.0
    let timeToUpdateAPI: Double = 60
    let initialLocation: CLLocation = CLLocation(latitude: Double(51.5315118), longitude: Double(-0.2526943)) // very far away's London
    var lastLocationInfo: CLLocation!
    var currentLocationInfo: CLLocation!
    var lastUpdatetime: NSDate?
    var initialStart: Bool = true
    var atYouBikeRange: Bool = true
    var distanceToYouBikeInRange = 100000
    
    let APICall = APIManager()
    var stopInfoResult:[StopInfo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentLocationInfo = initialLocation
        
        navigationMapView.alpha = 0
        bikeStoptableView.alpha = 0
        headerTipsView.alpha = 0

        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        navigationMapView.delegate = self
    }
    
    func alertToUser(failedDistrict: [String]) {
        var failedString:String = ""
        for district in failedDistrict {
            failedString += "\(district)"
            failedDistrict.last != district ? failedString += "、" : ()
        }
        let alertController = UIAlertController(title: "發生錯誤", message: "\(failedString)即時資訊未能提取，但你仍可查詢其他地方即時資訊。\n請檢查網絡。如網絡沒有問題，則為開放資料網站出現錯誤，請稍候再嘗試", preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "知道了", style: .Default, handler: nil)
        alertController.addAction(alertAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func markDestinationStop(position: Int) {
        let stopName = stopInfoResult[position].stopName
        let coordinate = stopInfoResult[position].coordinate
        let availableBike = stopInfoResult[position].availableBike
        let availableSlot = stopInfoResult[position].availableSlot
        destinationMarker.title = "可借: \(availableBike) 可還: \(availableSlot)"
        destinationMarker.subtitle = stopName
        destinationMarker.coordinate = coordinate
        navigationMapView.addAnnotation(destinationMarker)
        atYouBikeRange ? navigationToBikeStop(coordinate) : zoomToAnnotation()
    }
    
    func zoomToAnnotation() {
        navigationMapView.showAnnotations([destinationMarker], animated: true)
    }
    
    func navigationToBikeStop(stopLocation: CLLocationCoordinate2D) {
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocationInfo.coordinate, addressDictionary: nil))
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
        let distance = APICall.distanceMeasure(currentLocationInfo.coordinate, to: destinationMarker.coordinate)
        distanceLeftLabel.text = "距離：\(distance)米"
    }
    
    func outOfAreaAlert() {
        let alert = UIAlertController(title: "溫馨提示", message: "你並沒有位於YouBike站點範圍，但你仍可以查詢各站即時資訊", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "知道了", style: .Cancel, handler: nil)
        alert.addAction(ok)
        self.presentViewController(alert, animated: true, completion: nil)
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
        if initialStart {
            HUD.show(.LabeledProgress(title: "即時資料加載中", subtitle: "請稍候"))
            APICall.setCurrentLocation(currentLocationInfo.coordinate)
            APICall.getAllStopInfo { (result, failedDistrict) in
                self.stopInfoResult = result.sort { $0.distanceFromYou < $1.distanceFromYou }
                failedDistrict.count > 0 ? self.alertToUser(failedDistrict) : ()
                if self.stopInfoResult.count > 0 {
                    // simulator with no location / actual place out of taipei
                    if self.currentLocationInfo == self.initialLocation || self.APICall.distanceMeasure(self.currentLocationInfo.coordinate, to: self.stopInfoResult[0].coordinate) > self.distanceToYouBikeInRange {
                        self.outOfAreaAlert()
                        self.atYouBikeRange = false
                    }
                    self.lastLocationInfo = self.currentLocationInfo
                    self.lastUpdatetime = NSDate()
                    self.markDestinationStop(0)
                    self.updateDistanceLable()
                    self.initialStart = false
                    self.bikeStoptableView.reloadData()
                    self.navigationMapView.alpha = 1
                    self.bikeStoptableView.alpha = 1
                    self.headerTipsView.alpha = 1
                    HUD.hide()
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocationInfo = locations[0]
        initialStart ? () : updateDistanceLable()
        if !initialStart && NSDate().compare(lastUpdatetime!.dateByAddingTimeInterval(timeToUpdateAPI)) == NSComparisonResult.OrderedDescending {
            lastUpdatetime = NSDate()
            APICall.setCurrentLocation(currentLocationInfo.coordinate)
            APICall.getAllStopInfo { (result, failedDistrict) in
                self.stopInfoResult = result.sort { $0.distanceFromYou < $1.distanceFromYou }
                failedDistrict.count > 0 ? self.alertToUser(failedDistrict) : ()
            }
        }
        if !initialStart && currentLocationInfo.distanceFromLocation(lastLocationInfo) > distanceToUpdatelocation {
            lastLocationInfo = currentLocationInfo
            recalculateDistance(currentLocationInfo)
            markDestinationStop(0)
            bikeStoptableView.reloadData()
        }
    }
    
    func recalculateDistance(updatedLocation:CLLocation) {
        for each in stopInfoResult {
            each.distanceFromYou = APICall.distanceMeasure(updatedLocation.coordinate, to: each.coordinate)
        }
        stopInfoResult = stopInfoResult.sort { $0.distanceFromYou < $1.distanceFromYou }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stopInfoResult.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("bikeStop_TableViewCell") as! bikeStop_TableViewCell
        cell.initWithData(stopInfoResult[indexPath.row])
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