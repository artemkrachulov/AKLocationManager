//
//  AKLocationManager.swift
//  Class file
//
//  Created by Krachulov Artem
//  Copyright (c) 2015 The Krachulovs. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//

import CoreLocation
import UIKit

@objc protocol AKLocationManagerDelegate {
  
  optional func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation)
  optional func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation)
  optional func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, withTimeInterval ti: NSTimeInterval)
  optional func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, withLoopModeAfterTimeInterval ti: NSTimeInterval)
//  optional func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterDistance distance: CLLocationDistance)
  
  // Errors
  optional func locationManagerCantDetectFirstLocation(manager: AKLocationManager)
  optional func locationManagerCantStartUpdatingLocation(manager: AKLocationManager)
  
  // Notifications
  optional func locationManagerReceivedDeniedNotification(manager: AKLocationManager)
  optional func locationManagerReceivedAllowedNotification(manager: AKLocationManager)

  optional func locationManagerAuthorized(manager: AKLocationManager)
  optional func locationManagerDenied(manager: AKLocationManager)
  // + background
}

class AKLocationManager: NSObject {
  
  // MARK: - Settings
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  var allowUpdateLocationInBackground: Bool = false
  
  // MARK: - Properties
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  var coreLocationManager: CLLocationManager! {
    didSet {
      if coreLocationManager != nil {
        coreLocationManager.delegate = self
      }
    }
  }
  
  // Observers
  
  private var observerObject: AnyObject!
  private var observerKeyPath: String!
  
  var myLocationObserver: CLLocation?
  var myLocation: CLLocation? {
    return coreLocationManager.location ?? myLocationObserver
  }
  
  // Delegate
  
  weak var delegate: AKLocationManagerDelegate?
  
  // Other
  
  private var authorizedFlag: Bool = false
  private var deniedFlag: Bool = false
  
  private var observerObjectFlag: Bool = false
  
  private var firstLocationTimer: NSTimer?
  private var firstLocationFlag: Bool = false
  private var firstLocationCounter: Int = 0
  
  private var loopLocationTimer: NSTimer?
  var loopLocationTimeInterval: NSTimeInterval = 5
  
  private var updateLocationTimer: NSTimer?
  private var updateLocationPausedFlag: Bool = true
  private var safeUpdatingLocationFlag: Bool = false
  var updateLocationTimeInterval: NSTimeInterval = 2
  
  private var appInBackgroundFlag: Bool = false
  private var appNotDeterminedFlag: Bool = false
  private var appAuthorizedFlad: Bool {
    return authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse
  }
  private var authorizationStatus: CLAuthorizationStatus {
    return CLLocationManager.authorizationStatus()
  }
  /*
  var updateDistance: CLLocationDistance! = 0
  var lastLocation: CLLocation!
  var distance: CLLocationDistance = 0.0
  */
  
  // MARK: - Initialization
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  override init() {
    super.init()
    
    addResignActiveObservers()
  }
  
  // MARK: - Methods
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  func requestForUpdatingLocation() {
    #if AKLocationManagerDEBUG
      print("requestForUpdatingLocation")
      print("")
    #endif    
    
    if coreLocationManager == nil {
      // automatically call requestWhenInUseAuthorization() method
      coreLocationManager = CLLocationManager()
      
      coreLocationManager.desiredAccuracy = kCLLocationAccuracyBest
      coreLocationManager.activityType = .Fitness
      coreLocationManager.distanceFilter = 1
    }

    if !appAuthorizedFlad {
      coreLocationManager.requestWhenInUseAuthorization()
    }
  }
  
  func startUpdatingLocation() {
    #if AKLocationManagerDEBUG
      print("startUpdatingLocation")
      print("")
    #endif
    
    // Release Start / Pause flag for manual updating
    updateLocationPausedFlag = false
    
    // Manually reset first location
    if firstLocationCounter != 0 {
      resetFirstLocationSettigs()
    }
    
    if appAuthorizedFlad {
      
      safeUpdatingLocationFlag = false
      startSafeUpdatingLocation()
      
    } else {
      
      delegate?.locationManagerCantStartUpdatingLocation?(self)
    }
  }
  
  func pauseUpdatingLocation() {
    #if AKLocationManagerDEBUG
      print("pauseUpdatingLocation")
      print("")
    #endif
    
    // Release Start / Pause flag for manual updating
    updateLocationPausedFlag = true
    
    pauseSafeUpdatingLocation()
  }
  
  func manualUpdateLocation() {
    
    resetAllTimers()
    
    startLoopLocationTimer()
    updatingLocation()
  }
  
  func resetAllTimers() {
    resetUpdateLocationTimer()
    resetLoopLocationTimer()
  }
  
  func willObservervingObject(target: AnyObject, forKeyPath: String) {
    observerObject = target
    observerKeyPath = forKeyPath
  }
  
  func stopObservervingObject() {
    guard observerObjectFlag else {
      return
    }
    
    observerObject?.removeObserver(self, forKeyPath: observerKeyPath)
    observerObject = nil
    observerKeyPath = nil
    observerObjectFlag = false
  }
  
  func destroy() {
    
    // Destroy
    stopObservervingObject()
    NSNotificationCenter.defaultCenter().removeObserver(self)
    
    resetFirstLocationSettigs()
    pauseSafeUpdatingLocation()
    
    coreLocationManager = nil
  }

  private func startSafeUpdatingLocation() {
    guard appAuthorizedFlad else {
      return
    }
    
    if appInBackgroundFlag {
      if allowUpdateLocationInBackground {
        _startSafeUpdatingLocation()
      }
    } else  {
      _startSafeUpdatingLocation()
    }
  }
  
  private func _startSafeUpdatingLocation() {
    #if AKLocationManagerDEBUG
      print("_safeUpdatingLocation")
      print(" ")
    #endif
    
    guard !updateLocationPausedFlag && !safeUpdatingLocationFlag else {
      return
    }
    safeUpdatingLocationFlag = true
    
    if observerObject != nil {
      observerObjectFlag = true
      observerObject?.addObserver(self, forKeyPath: observerKeyPath, options: NSKeyValueObservingOptions.New, context: nil)
      coreLocationManager.stopUpdatingLocation()
    } else {
      coreLocationManager.startUpdatingLocation()
    }
    
    startFirstLocationTimer()
    
    guard myLocation != nil else {
      return
    }
    
    startLoopLocationTimer()
    updatingLocation()
  }
  
  private func pauseSafeUpdatingLocation() {
    if appInBackgroundFlag {
      if !allowUpdateLocationInBackground {
        _pauseSafeUpdatingLocation()
      }
    } else  {
      _pauseSafeUpdatingLocation()
    }
  }
  
  private func _pauseSafeUpdatingLocation() {
    #if AKLocationManagerDEBUG
      print("_pauseSafeUpdatingLocation")
      print("")
    #endif
    
    safeUpdatingLocationFlag = false
    
    coreLocationManager.stopUpdatingLocation()
    
    if observerObjectFlag {
      observerObjectFlag = false
      observerObject?.removeObserver(self, forKeyPath: observerKeyPath)
    }
    
    resetAllTimers()
  }
  
  
  
  private func addResignActiveObservers() {
    NSNotificationCenter.defaultCenter().addObserver(self,
                                                     selector:#selector(appWillResignActiveNotification),
                                                     name:UIApplicationWillResignActiveNotification,
                                                     object:nil)
    NSNotificationCenter.defaultCenter().addObserver(self,
                                                     selector:#selector(appDidBecomeActiveNotification),
                                                     name:UIApplicationDidBecomeActiveNotification,
                                                     object:nil)
  }
  
  private func updatingLocation() {
    guard !updateLocationPausedFlag || myLocation != nil else {
      return
    }
    
    // 1
    delegate?.locationManager?(self, didUpdateLocation: myLocation!)
    
    // 2
    if !firstLocationFlag {
      firstLocationFlag = true
      
      resetFirstLocationTimer()
      
      delegate?.locationManager?(self, didGetFirstLocation: myLocation!)
      
      startLoopLocationTimer()      
    }
    
    
    
    /*
     if lastLocation != nil {
     
     
     let _distance = myLocation!.distanceFromLocation(lastLocation)
     
     let time = myLocation!.timestamp.timeIntervalSinceDate(lastLocation.timestamp)
     
     let speed = _distance/time
     
     var multiplier:Double = 1
     
     switch speed {
     case 100 ... 250:
     multiplier = 2
     default: ()
     }
     
     // y=0.3x^2
     
     
     updateDistance = 0.3 * speed * speed * multiplier
     
     if updateDistance < 5 {
     updateDistance = 5
     }
     
     
     distance += _distance
     
     
     if distance >= updateDistance {
     
     distance = 0
     
     
     delegate?.locationManager?(self, didUpdateLocation: myLocation!, afterDistance: updateDistance)
     }
     
     }
     
     lastLocation = myLocation
     */
    
    
    if updateLocationTimer == nil {
      updateLocationTimer = NSTimer.scheduledTimerWithTimeInterval(updateLocationTimeInterval,
                                                                   target: self,
                                                                   selector: #selector(resetUpdateLocationTimer),
                                                                   userInfo: nil,
                                                                   repeats: false)
      
      delegate?.locationManager?(self, didUpdateLocation: myLocation!, withTimeInterval: updateLocationTimeInterval)
    }
  }
  
  
  @objc private func resetUpdateLocationTimer() {
    updateLocationTimer?.invalidate()
    updateLocationTimer = nil
  }
  
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  private func startLoopLocationTimer() {
    if loopLocationTimer == nil {
      loopLocationTimer = NSTimer.scheduledTimerWithTimeInterval(loopLocationTimeInterval,
                                                                 target: self,
                                                                 selector: #selector(loopLocationTimerAction),
                                                                 userInfo: nil,
                                                                 repeats: true)
      loopLocationTimerAction()
    }
  }
  
  @objc private func loopLocationTimerAction() {
    if let myLocation = myLocation {
      delegate?.locationManager?(self, didUpdateLocation: myLocation, withLoopModeAfterTimeInterval: updateLocationTimeInterval)
    }
  }
  
  private func resetLoopLocationTimer() {
    loopLocationTimer?.invalidate()
    loopLocationTimer = nil
  }
  
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  private func startFirstLocationTimer() {
    #if AKLocationManagerDEBUG
      print("startFirstLocationTimer")
      print("")
    #endif
    
    if !firstLocationFlag && firstLocationTimer == nil {
      firstLocationTimer = NSTimer.scheduledTimerWithTimeInterval(1,
                                                                  target: self,
                                                                  selector: #selector(firstLocationTimerAction),
                                                                  userInfo: nil,
                                                                  repeats: true)
      firstLocationTimerAction()
    }
  }
  @objc private func firstLocationTimerAction() {
    if !firstLocationFlag {
      if let myLocation = myLocation {

        firstLocationFlag = true
        resetFirstLocationTimer()
        
        delegate?.locationManager?(self, didGetFirstLocation: myLocation)
          
        startLoopLocationTimer()
      } else {
        
        firstLocationCounter += 1
        
        while firstLocationCounter == 5 {

          resetFirstLocationSettigs()

  //        pauseUpdatingLocation()
          
          delegate?.locationManagerCantDetectFirstLocation?(self)
          return
        }
      }
    }
  }
  private func resetFirstLocationTimer() {
    firstLocationTimer?.invalidate()
    firstLocationTimer = nil
  }
  
  private func resetFirstLocationSettigs() {
    resetFirstLocationTimer()
    
    firstLocationFlag = false
    firstLocationCounter = 0
  }
  
  // MARK: - Access
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  func locationAccessDenied(onComplete: (locationServicesEnabled: Bool) -> ()) {
    if authorizationStatus == .Denied {
      onComplete(locationServicesEnabled: CLLocationManager.locationServicesEnabled())
    }
  }
  
  func locationAccessRestricted(onComplete: (locationServicesEnabled: Bool) -> ()) {
    if authorizationStatus == .Restricted {
      onComplete(locationServicesEnabled: CLLocationManager.locationServicesEnabled())
    }
  }
  
  func locationAccessNotDetermined(onComplete: (locationServicesEnabled: Bool) -> ()) {
    if authorizationStatus == .NotDetermined {
      onComplete(locationServicesEnabled: CLLocationManager.locationServicesEnabled())
    }
  }
  
  deinit {
    print("deinit AKLocationManager")
  }
}

// MARK: - CLLocationManagerDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKLocationManager: CLLocationManagerDelegate {
  
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    #if AKLocationManagerDEBUG
      print("didChangeAuthorizationStatus \(status)")
      print("")
    #endif
    
    switch status {
    case .AuthorizedAlways, .AuthorizedWhenInUse:
      
      if appNotDeterminedFlag || appInBackgroundFlag {
        delegate?.locationManagerReceivedAllowedNotification?(self)
      }
      if !authorizedFlag {
        authorizedFlag = true
        deniedFlag = false
        
        delegate?.locationManagerAuthorized?(self)
      }
      
      startSafeUpdatingLocation()
      
      
    
    case .NotDetermined:
      appNotDeterminedFlag = true
    case .Denied:

      pauseSafeUpdatingLocation()
      if appNotDeterminedFlag || appInBackgroundFlag {
        delegate?.locationManagerReceivedDeniedNotification?(self)
      }
      
      if !deniedFlag {
        deniedFlag = true
        authorizedFlag = false
          
        delegate?.locationManagerDenied?(self)
      }
      
      
    case .Restricted: ()
    }
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    updatingLocation()
  }
}

// MARK: - Observer
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKLocationManager {
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if let keyPath = keyPath where keyPath == "myLocation" {
      myLocationObserver = change![NSKeyValueChangeNewKey] as? CLLocation
      updatingLocation()
    }
  }

  func appWillResignActiveNotification() {
    #if AKLocationManagerDEBUG
      print("appWillResignActiveNotification")
      print("")
    #endif
    
    appInBackgroundFlag = true
    pauseSafeUpdatingLocation()
  }
  
  func appDidBecomeActiveNotification() {
    #if AKLocationManagerDEBUG
      print("appDidBecomeActiveNotification")
      print("")
    #endif

    appInBackgroundFlag = false
    startSafeUpdatingLocation()
  }
}