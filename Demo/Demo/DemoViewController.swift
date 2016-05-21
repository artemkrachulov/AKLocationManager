//
//  DemoViewController.swift
//  AKLocationManager Demo
//
//  Created by Artem Krachulov.
//  Copyright © 2016 Krachulov Artem. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//

import UIKit
import GoogleMaps

class DemoViewController: UIViewController {
  
  //  MARK: - Outlets

  @IBOutlet weak var location1View: UIView!
  @IBOutlet weak var location1Label: UILabel!
  @IBOutlet weak var location2View: UIView!
  @IBOutlet weak var location2Label: UILabel!
  @IBOutlet weak var location3View: UIView!
  @IBOutlet weak var location3Label: UILabel!
  @IBOutlet weak var location4View: UIView!
  @IBOutlet weak var location4Label: UILabel!
  
  //  Objects
  
  var locationManager: AKLocationManager! {
    didSet { locationManager.delegate = self }
  }
  
  var mapView: GMSMapView!
  
  //  Other
  
  var google = false

  //  MARK: - Life cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    
    locationManager = AKLocationManager()
    
    //  If you want initialize CLLocationManager with custom settings:
    //         let coreLocationManager = CLLocationManager()
    //         coreLocationManager.desiredAccuracy = kCLLocationAccuracyBest
    //         coreLocationManager.activityType = .AutomotiveNavigation
    //         coreLocationManager.distanceFilter = 5
    //         coreLocationManager.delegate = self
    //         locationManager.locationManager = coreLocationManager
    //
    //  Pass 2 follow protocol methods to AKLocationManager class:
    //  - locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    //  - locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    //
    
    if google {
      
      mapView = GMSMapView()
      mapView.alpha = 0
      mapView.frame = view.frame
      
      view.addSubview(mapView)
      view.sendSubviewToBack(mapView)
      
      locationManager.addObserver(mapView, forKeyPath: "myLocation")
     
      //  NOTICE!!!
      //  Before enable my location with myLocationEnabled property from GMSMapView class
      //  call requestForUpdatingLocation method. This will run authorization process in AKLocationManager
      //
      //  1
      locationManager.requestForUpdatingLocation()
      //  2
      mapView.myLocationEnabled = true
      //  3
      locationManager.startUpdatingLocation()
    
    } else {
      locationManager.startUpdatingLocationWithRequest()
      
      //  or
      //
      //  locationManager.requestForUpdatingLocation()
      //  locationManager.startUpdatingLocation()
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    locationManager.startUpdatingLocation()
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    locationManager.locationAccessDenied { (locationServicesEnabled) -> () in
      let alertController = UIAlertController(title: "Location access disabled", message:
        "For searching caches, please open this app's settings and set location access to 'While Using the App'.", preferredStyle: UIAlertControllerStyle.Alert)
      
      alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
      
      alertController.addAction(UIAlertAction(title: "Open Settings",
        style: UIAlertActionStyle.Default,
        handler: { (success) in
          if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
            UIApplication.sharedApplication().openURL(url)
          }
      })
      )
      
      self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    locationManager.locationAccessRestricted { (locationServicesEnabled) -> () in }
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    
    locationManager.stopUpdatingLocation()
  }
  
  deinit { print("deinit \(self.dynamicType)") }
  
  //  MARK: - Actions

  @IBAction func pauseUpdateAction(sender: UIBarButtonItem) {
    locationManager.stopUpdatingLocation()
  }
  
  @IBAction func resumeUpdateAction(sender: UIBarButtonItem) {
    locationManager.startUpdatingLocation()
  }
  
  //  MARK: - Helper

  func animateView(view: UIView, label: UILabel, location: CLLocation) {
    UIView.animateWithDuration(0.3,
                               delay: 0,
                               options: UIViewAnimationOptions.CurveEaseIn,
                               animations: {
                                view.backgroundColor = UIColor.yellowColor()
    }) { (Bool) in
      UIView.animateWithDuration(0.8,
                                 delay: 0,
                                 options: UIViewAnimationOptions.CurveEaseOut,
                                 animations: {
                                  view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
        }, completion: nil)
    }
    label.text = String(location.coordinate.latitude) + " / " + String(location.coordinate.longitude)
  }
}

//  MARK: - AKLocationManagerDelegate

extension DemoViewController: AKLocationManagerDelegate {
  
  func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation) {
    print("\(self.dynamicType) Locaiton manager get first location \n")
    
    animateView(location1View, label: location1Label, location: location)
        
    if google {      
      mapView.camera = GMSCameraPosition.cameraWithLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 12)
      mapView.alpha = 1
    }
  }
  
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation) {
    print("\(self.dynamicType) Locaiton manager updated location \n")
    
    animateView(location2View, label: location2Label, location: location)
  }
  
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterTimeInterval ti: NSTimeInterval) {
    print("\(self.dynamicType) Locaiton manager updated location after ti \(ti) \n")
    
    animateView(location3View, label: location3Label, location: location)
  }
  
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation?, inLoopModeAfterTimeInterval ti: NSTimeInterval) {
    print("\(self.dynamicType) Locaiton manager updated location after ti \(ti) in loop mode \n")
    
    if let location = location {
      animateView(location4View, label: location4Label, location: location)
    }
  }
}

//  MARK: - CLLocationManagerDelegate

/*
extension DemoViewController: CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    locationManager.locationManager(manager, didChangeAuthorizationStatus: status)
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    locationManager.locationManager(manager, didUpdateLocations: locations)
  }
}*/
