//
//  AKLocationManager.swift
//  Main class
//
//  Created by Krachulov Artem
//  Copyright (c) 2015 Krachulov Artem. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//

import CoreLocation
import CoreMotion
import UIKit

enum AKLocationManagerError: ErrorType {
  
  /**
   *  Error returns when AKLocationManager can't start 
   *  detecting activity with CMMotionActivity class.
   */
  case ActivityManagerNotAvailable
  
  /**
   *  Error returns when AKLocationManager can't start updating
   *  location, because core location status is NotDetermined | Restricted | Denided.
   */
  case LocationManagerNotAuthorized
  
  /**
   *  Error returns when ditectFirsLocationTime time is off.
   */
  case LocationManagerCantDetectFirstLocation
}

protocol AKLocationManagerDelegate : class {
  
  func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation)
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation)
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterTimeInterval ti: NSTimeInterval)
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation?, inLoopModeAfterTimeInterval ti: NSTimeInterval)
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterDistance distance: CLLocationDistance)
  
  // User change authorization status
  func locationManagerReceivedDeniedNotification(manager: AKLocationManager)
  func locationManagerReceivedAllowedNotification(manager: AKLocationManager)

  // Core location manager receive changing authorization status
  func locationManagerAuthorized(manager: AKLocationManager)
  func locationManagerDenied(manager: AKLocationManager)
  
  // Errors
  func locationManager(manager: AKLocationManager, didGetError error: AKLocationManagerError)
}

class AKLocationManager: NSObject {
  
  // MARK: - Settings
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  /**
   *  Allows update location when applicaiton in background mode. False value
   *  will pause / start updation when application go / out from background mode.
   */
  var allowUpdateLocationInBackground: Bool = true
  
  /**
   *  Specifies the update time intervar in secounds.
   */
  var loopLocationTimeInterval: NSTimeInterval = 5
  
  /**
   *  Specifies the minimum update time intervar in secounds.
   */
  var updateLocationTimeInterval: NSTimeInterval = 2
  
  /**
   *  Specifies the minimum update distance in meters. This distance can be 
   *  increased automatically, depending on moving speed. To enable this, set incleaseUpdatedDistanceOnSpeedChange property
   *  to true value.
   */  
  var minimumUpdateDistance: CLLocationDistance = 50
  
  /**
   *  True value of this property will increase minimum update distance
   *  automatically, depending on moving speed. 
   *  Formula: 0.3xspeed^2. 
   *  But not less minimumUpdateDistance property value.
   */
  var incleaseUpdatedDistanceOnSpeedChange: Bool = false
  
  /**
   *  Specifies the time interval in secounds when AKLocationManager will try to
   *  get first location. If location undefined and timer is finished 
   *  class will return error LocationManagerCantDetectFirstLocation.
   */
  var ditectFirsLocationTime: Int = 5
  
  // Delegate
  weak var delegate: AKLocationManagerDelegate?
  
  // MARK: - Properties
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  var locationManager: CLLocationManager? {
    didSet { locationManager?.delegate = self }
  }
  
  var myLocation: CLLocation? {
    return locationManager?.location
  }
  
  private var previousMyLocation: CLLocation!
  private var previousRefreshedDate: NSDate!
  private var distanceFromLastUpdate: CLLocationDistance = 0.0
  
  private var activityManager: CMMotionActivityManager?
  private var currentActivity: CMMotionActivity?
  
  // Observers
  
  private var observerObject: AnyObject!
  private var observerKeyPath: String!
  
  // Other
  
  private var authorizedFlag: Bool = false
  private var deniedFlag: Bool = false
  
  private var observerObjectFlag: Bool = false
  
  private var firstLocationTimer: NSTimer?
  private var firstLocationFlag: Bool = false
  
  
  private var firstLocationCounter: Int = 0
  
  private var loopUpdateLocationTimer: NSTimer?
  private var updateLocationTimer: NSTimer?
  
  private var updateLocationStartedFlag: Bool = false
  
  

  
  private var appInBackgroundFlag: Bool = false
  
  /**
   *  This property using to detect if user manually change authorization status
   */
  private var appNotDeterminedFlag: Bool = false
  
  
  private func appAuthorizedFlad() throws -> Bool {
    guard authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse else {
      throw AKLocationManagerError.LocationManagerNotAuthorized
    }
    
    return true
  }
  
  private var authorizationStatus: CLAuthorizationStatus { return CLLocationManager.authorizationStatus() }
  
  
  private var enableActivityManager: Bool = false
  
  // MARK: - Initialization
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  /*
  override init() {
    super.init()
    
    addResignActiveObservers()
  }*/
  
  convenience init(enableActivityManager: Bool) {
    self.init()
    
    addResignActiveObservers()
    
    self.enableActivityManager = enableActivityManager
  }
  
  // MARK: - Methods
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  func requestForUpdatingLocation() {
    
    #if AKLocationManagerDEBUG
      print("requestForUpdatingLocation")
      print("")
    #endif    
    
    if locationManager == nil {
      
      locationManager = CLLocationManager() // initalization will call requestWhenInUseAuthorization() method
      locationManager!.desiredAccuracy = kCLLocationAccuracyBest
      locationManager!.activityType = .Fitness
      locationManager!.distanceFilter = 1
    }
    
    if enableActivityManager {
      if ( CMMotionActivityManager.isActivityAvailable() ) {
        
        activityManager = CMMotionActivityManager()
      } else {
        
        delegate?.locationManager(self,
                                  didGetError: .ActivityManagerNotAvailable)
      }
    }

    do {
      try appAuthorizedFlad()
    } catch {
      
        locationManager?.requestWhenInUseAuthorization()
    }
  }
  
  func startUpdatingLocation() {
    
    #if AKLocationManagerDEBUG
      print("startUpdatingLocation")
      print("")
    #endif
    
    /**
     *  Global flag to detect if
     *  startUpdatingLocation method was called
     */
    updateLocationStartedFlag = true
    
    /**
     *  Manually reset first location.
     *  When user call this method again
     */
    if firstLocationCounter != 0 {
      firstLocationCounter = 0
    }
    
    do {
      try appAuthorizedFlad()
      
      _startSafeUpdatingLocationFlag = false
       startSafeUpdatingLocation()
      
    } catch {
      
//      delegate?.locationManager(self,
//                                didGetError: .LocationManagerNotAuthorized)
    }
  }
  
  func startUpdatingLocationWithRequest() {
    requestForUpdatingLocation()
    startUpdatingLocation()
  }
  
  func pauseUpdatingLocation() {
    
    #if AKLocationManagerDEBUG
      print("pauseUpdatingLocation")
      print("")
    #endif
    
    /**
     *  Release flag
     */
    updateLocationStartedFlag = false
    
    pauseSafeUpdatingLocation()
  }
  
  func updateLocation() {
    resetLocationTimers()
    _updateLocation(myLocation)
  }
  
  func startObservervingObject(target: AnyObject, forKeyPath: String) {
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
  
  func resetSettings() {
    allowUpdateLocationInBackground = false
    loopLocationTimeInterval = 5
    updateLocationTimeInterval = 2
    minimumUpdateDistance = 50
    incleaseUpdatedDistanceOnSpeedChange = false
    ditectFirsLocationTime = 5
  }
  func destroy() {
    
    /// Destroy
    /// 1. Background notiications
    NSNotificationCenter.defaultCenter().removeObserver(self)
    
    /// 2.1. CLLocationManager
    /// 2.2. CMMotionActivityManager
    /// 2.3. Object
    /// 2.4.a Location timers
    
    _pauseSafeUpdatingLocation()
    
    /// 2.4.b First location timer
    
    firstLocationTimerReset()
    
    /// 3. Object data
    observerObject = nil
    observerKeyPath = nil
    
    /// 4. Managers
    locationManager = nil
    activityManager = nil
    
    resetSettings()
  }
  
  // MARK: - Pivate methods
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  private func startSafeUpdatingLocation() {
    
    do {
      try appAuthorizedFlad()
      
      if appInBackgroundFlag {
        if allowUpdateLocationInBackground {
          
          _startSafeUpdatingLocation()
        }
      } else  {
        
        _startSafeUpdatingLocation()
      }
    } catch {}
  }
  
  /**
   *  This property (flag) is used to prevent loops execution method name
   */
  private var _startSafeUpdatingLocationFlag: Bool = false
  
  private func _startSafeUpdatingLocation() {
    
    #if AKLocationManagerDEBUG
      print("_safeUpdatingLocation")
      print(" ")
    #endif
    
    /// Сhecks:
    /// 1. Global
    guard updateLocationStartedFlag else {
      return
    }

    /// 2. Looping
    guard !_startSafeUpdatingLocationFlag else {
      return
    }
    _startSafeUpdatingLocationFlag = true
    
    /// Start services:
    /// 1. CLLocationManager
    locationManager?.startUpdatingLocation()
    
    /// 2. CMMotionActivityManager
    activityManager?.startActivityUpdatesToQueue(NSOperationQueue.mainQueue(),
                                                 withHandler: { (data) in
                                                  self.currentActivity = data
    })
    
    /// 3. Object
    if observerObject != nil && !observerObjectFlag {
      
      observerObject?.addObserver(self, forKeyPath: observerKeyPath, options: NSKeyValueObservingOptions.New, context: nil)
      observerObjectFlag = true
    }
    
    firstLocationTimerStart()
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
    
    /// Reset flag
    _startSafeUpdatingLocationFlag = false
    
    /// Stop services:
    /// 1. CLLocationManager
    locationManager?.stopUpdatingLocation()
    
    /// 2. CMMotionActivityManager
    activityManager?.stopActivityUpdates()
    
    /// 3. Object
    if observerObjectFlag {
      
      observerObject?.removeObserver(self, forKeyPath: observerKeyPath)
      observerObjectFlag = false
    }
    
    resetLocationTimers()
  }
  
  /**
   *  Reset updateLocationTimer and loopUpdateLocationTimer
   */
  private func resetLocationTimers() {
    
    /// 1. Update with time interval timer
    updateLocationTimerReset()
    
    /// 2. Loop timer
    loopUpdateLocationTimerReset()
  }

  private func _updateLocation(location: CLLocation?) {
    
    guard /*updateLocationStartedFlag ||*/ myLocation != nil else {
      return
    }
    
    /// User methods:
    /// 1. Update
    delegate?.locationManager(self, didUpdateLocation: myLocation!)
    
    /// 3. Update after time interval
    updateLocationTimerStart()
  }
  
  private func addResignActiveObservers() {
    
    let nc = NSNotificationCenter.defaultCenter()
    
    nc.addObserver(self,
                   selector:#selector(appWillResignActiveNotification),
                   name:UIApplicationWillResignActiveNotification,
                   object:nil)
    
    nc.addObserver(self,
                   selector:#selector(appDidBecomeActiveNotification),
                   name:UIApplicationDidBecomeActiveNotification,
                   object:nil)
  }
  
  // MARK: - Timers
  //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
  
  private func updateLocationTimerStart() {
    
    #if AKLocationManagerDEBUG
      print("updateLocationTimerStart")
      print("")
    #endif
    
    if updateLocationTimer == nil {
      
      updateLocationTimer = NSTimer.scheduledTimerWithTimeInterval(updateLocationTimeInterval,
                                                                   target: self,
                                                                   selector: #selector(updateLocationTimerReset),
                                                                   userInfo: nil,
                                                                   repeats: false)
      
      delegate?.locationManager(self, didUpdateLocation: myLocation!, afterTimeInterval: updateLocationTimeInterval)
    }
  }
  
  @objc private func updateLocationTimerReset() {
    
    updateLocationTimer?.invalidate()
    updateLocationTimer = nil
  }
  
  private func loopUpdateLocationTimerStart() {
    
    #if AKLocationManagerDEBUG
      print("loopLocationTimerStart")
      print("")
    #endif
    
    if loopUpdateLocationTimer == nil {
      
      loopUpdateLocationTimer = NSTimer.scheduledTimerWithTimeInterval(loopLocationTimeInterval,
                                                                 target: self,
                                                                 selector: #selector(loopUpdateLocationTimerAction),
                                                                 userInfo: nil,
                                                                 repeats: true)
      loopUpdateLocationTimerAction()
    }
  }
  
  @objc private func loopUpdateLocationTimerAction() {
    
    delegate?.locationManager(self,
                              didUpdateLocation: myLocation,
                              inLoopModeAfterTimeInterval: updateLocationTimeInterval)
  }
  
  private func loopUpdateLocationTimerReset() {
    
    loopUpdateLocationTimer?.invalidate()
    loopUpdateLocationTimer = nil
  }
  
  private func firstLocationTimerStart() {
    
    #if AKLocationManagerDEBUG
      print("firstLocationTimerStart")
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

        delegate?.locationManager(self,
                                  didGetFirstLocation: myLocation)
        
        firstLocationFlag = true
        
        firstLocationTimerReset()
        
        loopUpdateLocationTimerStart()
        
      } else {
        
        firstLocationCounter += 1
        while firstLocationCounter == ditectFirsLocationTime {

          delegate?.locationManager(self,
                                    didGetError: .LocationManagerCantDetectFirstLocation)
          return
        }
      }
    }
  }
  
  private func firstLocationTimerReset() {
    
    firstLocationTimer?.invalidate()
    firstLocationTimer = nil
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
        
        delegate?.locationManagerReceivedAllowedNotification(self)
      }
      
      if !authorizedFlag {
        delegate?.locationManagerAuthorized(self)
        
        deniedFlag = false
        authorizedFlag = true
      }
      
      startSafeUpdatingLocation()
      
    case .NotDetermined:
      appNotDeterminedFlag = true
      
    case .Denied:

      pauseSafeUpdatingLocation()
      
      if appNotDeterminedFlag || appInBackgroundFlag {
        
        delegate?.locationManagerReceivedDeniedNotification(self)
      }
      
      if !deniedFlag {
        delegate?.locationManagerDenied(self)
        
        deniedFlag = true
        authorizedFlag = false
      }
    case .Restricted: ()
    }
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    guard let myLocation = locations.first else {
      return
    }
    _updateLocation(myLocation)
    
    if previousMyLocation != nil {
      
      let distance = CLLocationDistance(myLocation.distanceFromLocation(previousMyLocation))
      
      if enableActivityManager {
        if CMMotionActivityManager.isActivityAvailable() {
          if let currentActivity = currentActivity {
            if !currentActivity.unknown && !currentActivity.stationary {
              
              distanceFromLastUpdate += distance
            }
          }
        } else {
          distanceFromLastUpdate += distance
        }
      } else {
        distanceFromLastUpdate += distance
      }
      
      // Accuracy
      
      // Distance
      var currentUpdatedDistance = minimumUpdateDistance
      
      if incleaseUpdatedDistanceOnSpeedChange {
        
        // Stay       0           km/h
        // Walk       0   - 5     km/h
        // Run        16  - 25    km/h
        // Bicycle    16  - 40    km/h
        // Car        60  - 180   km/h
        // Super Car  180 - 320   km/h
        // Fly        500 – 1000  km/h
        
        let time = previousRefreshedDate.timeIntervalSinceNow
        previousRefreshedDate = NSDate()
        
        let speed = (distance * 1000) / (time * -3600) // km/h
        
        currentUpdatedDistance = 0.3 * speed * speed + 50
      }
      
      if distanceFromLastUpdate >= currentUpdatedDistance {
        
        distanceFromLastUpdate = 0
        delegate?.locationManager(self,
                                  didUpdateLocation: myLocation,
                                  afterDistance: currentUpdatedDistance)
      }
    }
    
    previousMyLocation = myLocation
  }
}

// MARK: - Custom location Observer
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKLocationManager {
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    
    if let keyPath = keyPath where keyPath == "myLocation" {
      
      _updateLocation(change![NSKeyValueChangeNewKey] as? CLLocation)
    }
  }
}

// MARK: - Background Observer
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKLocationManager {
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


extension AKLocationManagerDelegate {
  func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation) {}
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation) {}
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterTimeInterval ti: NSTimeInterval) {}
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation?, inLoopModeAfterTimeInterval ti: NSTimeInterval)  {}
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterDistance distance: CLLocationDistance) {}
  func locationManager(manager: AKLocationManager, didGetError error: AKLocationManagerError) {}
  func locationManagerReceivedDeniedNotification(manager: AKLocationManager) {}
  func locationManagerReceivedAllowedNotification(manager: AKLocationManager) {}
  func locationManagerAuthorized(manager: AKLocationManager) {}
  func locationManagerDenied(manager: AKLocationManager) {}
}
