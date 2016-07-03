//
//  ViewController.swift
//  LocationTracker
//
//  Created by Aris Culala on 13/1/16.
//  Copyright © 2016 arisculala. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate {


    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapViewSegmentedControl: UISegmentedControl!

    var locManager: CLLocationManager!
    var myLocations: [CLLocation] = []
    var initialLocation: CLLocation!

    
    var searchController:UISearchController!
    var annotation:MKAnnotation!
    var localSearchRequest:MKLocalSearchRequest!
    var localSearch:MKLocalSearch!
    var localSearchResponse:MKLocalSearchResponse!
    var error:NSError!
    var pointAnnotation:MKPointAnnotation!
    var pinAnnotationView:MKPinAnnotationView!


    override func viewDidLoad() {
        super.viewDidLoad()

        //Check if location service for the app is enabled
        if CLLocationManager.locationServicesEnabled(){
            //Setup our Location Manager
            locManager = CLLocationManager()
            locManager.delegate = self
            locManager.desiredAccuracy = kCLLocationAccuracyBest
            locManager.requestAlwaysAuthorization()
            locManager.startUpdatingLocation()
        
            //Setup our Map View
            mapView.delegate = self
            mapView.mapType = MKMapType.Standard
            mapView.showsUserLocation = true
        } else {
            // Create alert here
            let alertController = UIAlertController(title: "Turn On Location Services to Allow LocationTracker to Determine Your Location", message:
                "Your location is required to show where you are on a map and find addresses and places near you.", preferredStyle: UIAlertControllerStyle.Alert)
            
            let settingsAction = UIAlertAction(title: "Settings", style: .Default) { (_) -> Void in
                let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                if let url = settingsUrl {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
            alertController.addAction(settingsAction)
            alertController.addAction(cancelAction)
            
            presentViewController(alertController, animated: true, completion: nil);
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        myLocations = locations
        let userLocation:CLLocation = myLocations[0]
        initialLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        centerMapOnLocation(initialLocation)
        locManager.stopUpdatingLocation();
    }

    let regionRadius: CLLocationDistance = 1000
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    @IBAction func mapViewSegmentedControlIndexChanged(sender: AnyObject) {
        switch mapViewSegmentedControl.selectedSegmentIndex {
        case 0:
            mapView.mapType = MKMapType.Standard
        case 1:
            mapView.mapType = MKMapType.Hybrid
        case 2:
            mapView.mapType = MKMapType.Satellite
        default:
            break
        }
    }

    @IBAction func showCurrentUserLocation(sender: AnyObject) {
        locManager.startUpdatingLocation()
    }

    @IBAction func showSearchBar(sender: AnyObject) {
        searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.delegate = self
        presentViewController(searchController, animated: true, completion: nil)
    }
    

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //1
        searchBar.resignFirstResponder()
        dismissViewControllerAnimated(true, completion: nil)
        if self.mapView.annotations.count != 0{
            annotation = self.mapView.annotations[0]
            self.mapView.removeAnnotation(annotation)
        }

        //2
        localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.startWithCompletionHandler { (localSearchResponse, error) -> Void in
            if localSearchResponse == nil {
                let alertController = UIAlertController(title: nil, message: "Place Not Found", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
                return
            }

            //3
            self.pointAnnotation = MKPointAnnotation()
            self.pointAnnotation.title = searchBar.text
            self.pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: localSearchResponse!.boundingRegion.center.latitude, longitude:     localSearchResponse!.boundingRegion.center.longitude)

            self.pinAnnotationView = MKPinAnnotationView(annotation: self.pointAnnotation, reuseIdentifier: nil)
            self.mapView.centerCoordinate = self.pointAnnotation.coordinate
            self.mapView.addAnnotation(self.pinAnnotationView.annotation!)

            self.initialLocation = CLLocation(latitude: self.pointAnnotation.coordinate.latitude, longitude: self.pointAnnotation.coordinate.longitude)

            self.centerMapOnLocation(self.initialLocation)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

