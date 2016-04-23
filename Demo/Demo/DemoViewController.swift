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
    
    // Init
    
    locationManager = AKLocationManager()
    

    // Var 1 (CLLocationManager with custom sittings)
    // 2 protocol methods must be passed to locationManager
    // - locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    // - locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    
//    let coreLocationManager = CLLocationManager()
//
//    coreLocationManager.desiredAccuracy = kCLLocationAccuracyBest
//    coreLocationManager.activityType = .Fitness
//    coreLocationManager.distanceFilter = 1
//
//    coreLocationManager.delegate = self
//
//    locationManager.coreLocationManager = coreLocationManager

    // Var 2 (CLLocationManager with sittings will initialized in AKLocationManager)
    
    locationManager.requestForUpdatingLocation()
    
    
    
    if google {
      
      mapView = GMSMapView()
      mapView.alpha = 0
      mapView.frame = view.frame
      
      view.addSubview(mapView)
      view.sendSubviewToBack(mapView)
      
      
      locationManager.willObservervingObject(mapView, forKeyPath: "myLocation")
     
      // Before enable my location
      // run requestForUpdatingLocation() method from  AKLocationManager class
      mapView.myLocationEnabled = true
    }
    

    
    locationManager.startUpdatingLocation()
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
    #if AKLocationManagerDEBUG
      print("VC      :: DemoViewController : AKLocationManagerDelegate")
      print("                                 ↳ func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation)")
      print("")
      print("                                   - location : \(location)")
      print("")
    #endif
    
    viewAnimation(location1View)
    location1Label.text = String(location.coordinate.latitude) + " / " + String(location.coordinate.longitude)
    
    if google {
      mapView.camera = GMSCameraPosition.cameraWithLatitude(51.5, longitude: -0.127, zoom: 12)
      mapView.alpha = 1
      
      foo2()
  
      
    }
  }
  func foo2() {
    let position = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.127)
    
    london = GMSMarker(position: position)
    
//    london.title = "London"
    
    
    
    
    /*let house = UIImage(named: "House")!.imageWithRenderingMode(.AlwaysTemplate)
    londonView = UIImageView(image: house)
    londonView.tintColor = UIColor.redColor()*/
//    london.iconView = londonView
//    london.tracksViewChanges = true
    london.map = mapView
  }
  func foo() {
    let position = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.127)
    
    let marker = GMSMarker(position: position)
    
    let view = UIView(frame: CGRectMake(0,0,60,60))
    let house = UIImage(named: "House")!.imageWithRenderingMode(.AlwaysTemplate)
    let pinImageView = UIImageView(image: house)
    pinImageView.tintColor = UIColor.redColor()
  let label = UILabel()
    label.text = "1"
    label.sizeToFit()
    view.addSubview(pinImageView)
    view.addSubview(label)
    
    let markerIcon = imageFromView(view)
    marker.icon = markerIcon
    marker.map = mapView
  }
  
  func imageFromView(view: UIView) -> UIImage {
  
    if (UIScreen.mainScreen().respondsToSelector(#selector(NSDecimalNumberBehaviors.scale))) {
      UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0.0)
    }
    else {
      UIGraphicsBeginImageContext(view.frame.size)
    }

    
    view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    
    let image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image
  }
  
  /*
  - (void)foo
  {
  GMSMarker *marker = [GMSMarker new];
  
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0,60,60)];
  UIImageView *pinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"myPin"]];
  UILabel *label = [UILabel new];
  label.text = @"1";
  //label.font = ...;
  [label sizeToFit];
  
  [view addSubview:pinImageView];
  [view addSubview:label];
  //i.e. customize view to get what you need
  
  
  UIImage *markerIcon = [self imageFromView:view];
  marker.icon = markerIcon;
  marker.map = self.mapView;
  }
  
  - (UIImage *)imageFromView:(UIView *) view
  {
  if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
  UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [[UIScreen mainScreen] scale]);
  } else {
  UIGraphicsBeginImageContext(view.frame.size);
  }
  [view.layer renderInContext: UIGraphicsGetCurrentContext()];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
  }
  */
  
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation) {
    
    print("VC      :: DemoViewController : AKLocationManagerDelegate")
    print("                                 ↳ func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation)")
    print("")
    print("                                   - location : \(location)")
    print("")
    
    viewAnimation(location2View)
    location2Label.text = String(location.coordinate.latitude) + " / " + String(location.coordinate.longitude)
  }
  
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, withTimeInterval ti: NSTimeInterval) {
    
    print("VC      :: DemoViewController : AKLocationManagerDelegate")
    print("                                 ↳ func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, withTI: NSTimeInterval)")
    print("")
    print("                                   - location :      \(location)")
    print("                                   - time interval : \(ti)")
    print("")
    
    viewAnimation(location3View)
    location3Label.text = String(location.coordinate.latitude) + " / " + String(location.coordinate.longitude)
  }
  
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, withLoopModeAfterTimeInterval ti: NSTimeInterval) {
    
    print("VC      :: DemoViewController : AKLocationManagerDelegate")
    print("                                 ↳ func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, inLoopMode withTI: NSTimeInterval)")
    print("")
    print("                                   - location :      \(location)")
    print("                                   - time interval : \(ti)")
    print("")
    
    viewAnimation(location4View)
    location4Label.text = String(location.coordinate.latitude) + " / " + String(location.coordinate.longitude)
  }
  
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterDistance distance: CLLocationDistance) {
    
    print("VC      :: DemoViewController : AKLocationManagerDelegate")
    print("                                 ↳ locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, withTI: NSTimeInterval)")
    print("")
    print("                                   - location : \(location)")
    print("                                   - distance : \(distance)")
    print("")
    
    viewAnimation(location5View)
    location5Label.text = String(location.coordinate.latitude) + " / " + String(location.coordinate.longitude)
  }
  
  func locationManagerCantDetectFirstLocation(manager: AKLocationManager) {
        #if AKLocationManagerDEBUG
    print("VC      :: DemoViewController : AKLocationManagerDelegate")
    print("                                 ↳ locationManagerCantDetectFirstLocation(manager: AKLocationManager)")
        #endif
  }
  
  func locationManagerCantStartUpdatingLocation(manager: AKLocationManager) {
    
    print("VC      :: DemoViewController : AKLocationManagerDelegate")
    print("                                 ↳ locationManagerCantStartUpdatingLocation(manager: AKLocationManager)")
    
  }
  
  func locationManagerReceivedDeniedNotification(manager: AKLocationManager) {
    #if AKLocationManagerDEBUG
    print("VC      :: DemoViewController : AKLocationManagerDelegate")
    print("                                 ↳ locationManagerReceivedDeniedNotification(manager: AKLocationManager)")
    #endif
  }

  func locationManagerReceivedAllowedNotification(manager: AKLocationManager) {
    print("VC      :: DemoViewController : AKLocationManagerDelegate")
    print("                                 ↳ locationManagerReceivedAllowedNotification(manager: AKLocationManager)")
//   
//    manager.startUpdatingLocation()
    
  }
  
  
  func locationManagerAuthorized(manager: AKLocationManager) {
    print("VC      :: DemoViewController : AKLocationManagerDelegate")
    print("                                 ↳ locationManagerAuthorized(manager: AKLocationManager)")
  }
  
  func locationManagerDenied(manager: AKLocationManager) {
    print("VC      :: DemoViewController : AKLocationManagerDelegate")
    print("                                 ↳ locationManagerDenied(manager: AKLocationManager)")
  }
  
}

// MARK: - CLLocationManagerDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension DemoViewController: CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    print("ss")
//    locationManager.locationManager(manager, didChangeAuthorizationStatus: status)
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//    locationManager.locationManager(manager, didUpdateLocations: locations)
  }
}
