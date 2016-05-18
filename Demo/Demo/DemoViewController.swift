//
//  DemoViewController.swift
//  AKLocationManager Demo
//
//  Created by Artem Krachulov.
//  Copyright © 2016 Krachulov Artem . All rights reserved.
//  Website: http://www.artemkrachulov.com/
//

import UIKit
import GoogleMaps

class DemoViewController: UIViewController {
  
  // MARK: - Segue flag
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  var google = false
  
  // MARK: - Outlets
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  @IBOutlet weak var locationView: UIView!
  @IBOutlet weak var locationLabel: UILabel!
  
  @IBOutlet weak var location1View: UIView!
  @IBOutlet weak var location1Label: UILabel!
  
  @IBOutlet weak var location2View: UIView!
  @IBOutlet weak var location2Label: UILabel!
  
  @IBOutlet weak var location3View: UIView!
  @IBOutlet weak var location3Label: UILabel!
  
  @IBOutlet weak var location4View: UIView!
  @IBOutlet weak var location4Label: UILabel!
  
  @IBOutlet weak var location5View: UIView!
  @IBOutlet weak var location5Label: UILabel!
  
  // Objects
  
  var locationManager: AKLocationManager! {
    didSet {
      locationManager.delegate = self
    }
  }
  
  var mapView: GMSMapView!

  
  // MARK: - Life cycle
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    locationManager = AKLocationManager(enableActivityManager: true)
    /**
     *  If you want initalzie CLLocationManager with custom settings:
     */
//         let coreLocationManager = CLLocationManager()
//         coreLocationManager.desiredAccuracy = kCLLocationAccuracyBest
//         coreLocationManager.activityType = .AutomotiveNavigation
//         coreLocationManager.distanceFilter = 5
//         coreLocationManager.delegate = self
//         locationManager.locationManager = coreLocationManager
    /**
     *  Pass 2 follow protocol methods to AKLocationManager class:
     *  - locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
     *  - locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
     */
   
    
    
    if google {
      
      mapView = GMSMapView()
      mapView.alpha = 0
      mapView.frame = view.frame
      
      view.addSubview(mapView)
      view.sendSubviewToBack(mapView)
      
      locationManager.startObservervingObject(mapView, forKeyPath: "myLocation")
     
      // NOTICE!!!
      // Before enable my location with myLocationEnabled property
      // from GMSMapView class
      // call requestForUpdatingLocation method.
      // This will run authorization process
      // in AKLocationManager
      locationManager.requestForUpdatingLocation()
      
      mapView.myLocationEnabled = true
      
      locationManager.startUpdatingLocation()
    
    } else {
      
      locationManager.requestForUpdatingLocation()
      locationManager.startUpdatingLocation()
      
      
//      locationManager.startUpdatingLocationWithRequest()
      
      // or 
      
//      locationManager.requestForUpdatingLocation()
//      locationManager.startUpdatingLocation()
    }
    

    
  }

  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    
    locationManager.locationAccessDenied { (locationServicesEnabled) -> () in
      
      print("VC ::::::: DemoViewController")
      print("Method ::: viewDidAppear")
      print("           - -")
      print("Message :: Location access denied")
      print("")
      
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
    
    locationManager.locationAccessRestricted { (locationServicesEnabled) -> () in
      print("VC ::::::: DemoViewController")
      print("Method ::: viewDidAppear")
      print("           - -")
      print("Message :: Location access restricted")
      print("")
    }
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    
    locationManager.pauseUpdatingLocation()
  }
  
  deinit {
    locationManager.destroy()
    
    print("deinit DemoViewController")
  }
  
  // MARK: - Actions
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  @IBAction func pauseUpdateAction(sender: UIBarButtonItem) {
    
    locationManager.pauseUpdatingLocation()
  }
  
  @IBAction func resumeUpdateAction(sender: UIBarButtonItem) {
    
    locationManager.startUpdatingLocation()
  }
  
  // MARK: - Helper
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  func viewAnimation(view: UIView) {
    
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
  }
  
  var london: GMSMarker!
  
  var londonView:UIImageView!
}

// MARK: - AKLocationManagerDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension DemoViewController: AKLocationManagerDelegate {
  
  func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation) {
    print("Locaiton manager get first location")
    
    viewAnimation(location1View)
    location1Label.text = String(location.coordinate.latitude) + " / " + String(location.coordinate.longitude)
    
    if google {
      
      mapView.camera = GMSCameraPosition.cameraWithLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 12)
      mapView.alpha = 1
    }
  }
  
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation) {
    print("Locaiton manager updated location")
    
    viewAnimation(location2View)
    location2Label.text = String(location.coordinate.latitude) + " / " + String(location.coordinate.longitude)
  }
  
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterTimeInterval ti: NSTimeInterval) {
    print("Locaiton manager updated location after ti \(ti)")
    viewAnimation(location3View)
    location3Label.text = String(location.coordinate.latitude) + " / " + String(location.coordinate.longitude)
  }
  
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation?, inLoopModeAfterTimeInterval ti: NSTimeInterval) {
    print("Locaiton manager updated location after ti \(ti) in loop mode")
    
    if let coordinate = location?.coordinate {
      viewAnimation(location4View)
      location4Label.text = String(coordinate.latitude) + " / " + String(coordinate.longitude)
    }
  }
  
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterDistance distance: CLLocationDistance) {
    print("Locaiton manager updated location after distance \(distance)")
    
    viewAnimation(location5View)
    location5Label.text = String(location.coordinate.latitude) + " / " + String(location.coordinate.longitude)
  }
  
  func locationManagerReceivedDeniedNotification(manager: AKLocationManager) {
    print("Locaiton manager received DENIDED notification from didChangeAuthorizationStatus method")
  }

  func locationManagerReceivedAllowedNotification(manager: AKLocationManager) {
    print("Locaiton manager received ALLOWED notification from didChangeAuthorizationStatus method")
  }
  
  func locationManagerAuthorized(manager: AKLocationManager) {
    print("User ALLOWED updating location")
  }
  
  func locationManagerDenied(manager: AKLocationManager) {
    print("User DENIDED updating location")
  }
  
  func locationManager(manager: AKLocationManager, didGetError error: AKLocationManagerError) {
    print("Locaiton manager did fail with error \(error)")
  }
}

// MARK: - CLLocationManagerDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
/*
extension DemoViewController: CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    locationManager.locationManager(manager, didChangeAuthorizationStatus: status)
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    locationManager.locationManager(manager, didUpdateLocations: locations)
  }
}*/
