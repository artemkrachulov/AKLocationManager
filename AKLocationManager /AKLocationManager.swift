//
//  AKLocationManager.swift
//  Base class
//  
//  Created by Krachulov Artem
//  Copyright (c) 2016 Krachulov Artem. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//

import CoreLocation
import CoreMotion
import UIKit

//  MARK: - AKLocationManagerNotification

enum AKLocationManagerNotification {
  case LocationManagerNotAuthorized
  case UserDeniedAuthorization
  case UserAllowedAuthorization
  case AuthorizationAllowed
  case AuthorizationDenied
  case GoToBackground
  case BackFromBackground
}

//  MARK: - AKLocationManagerError

enum AKLocationManagerError: ErrorType {
  
  /// Error returns when ditectFirsLocationTime time is off.
  
  case LocationManagerCantDetectFirstLocation
}

//  MARK: - AKLocationManagerDelegate

protocol AKLocationManagerDelegate : class {
  func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation)
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation)
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterTimeInterval ti: NSTimeInterval)
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation?, inLoopModeAfterTimeInterval ti: NSTimeInterval)
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterDistance distance: CLLocationDistance)
  
  // Errors
  
  func locationManager(manager: AKLocationManager, didGetError error: AKLocationManagerError)
  
  // Notifications
  
  func locationManager(manager: AKLocationManager, didGetNotification notification: AKLocationManagerNotification)
}

extension AKLocationManagerDelegate {
  func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation) {}
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation) {}
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterTimeInterval ti: NSTimeInterval) {}
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation?, inLoopModeAfterTimeInterval ti: NSTimeInterval)  {}
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterDistance distance: CLLocationDistance) {}
  func locationManager(manager: AKLocationManager, didGetError error: AKLocationManagerError) {}
  func locationManager(manager: AKLocationManager, didGetNotification notification: AKLocationManagerNotification) {}
}

//  MARK: - AKLocationManager

class AKLocationManager: NSObject {
  
  //  MARK: Settings
  
  /// Allows update location when applicaiton in background mode. False value
  /// will stop / start updating location when application go / back from "Background" state.
  ///
  var allowUpdateLocationInBackground: Bool = false
  
  /// Specifies the update time intervar in secounds.
  ///
  /// Class will call follow delegate method:
  ///
  ///     func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation?, inLoopModeAfterTimeInterval ti: NSTimeInterval)
  ///
  /// every n secounds.
  ///
  var loopLocationTimeInterval: NSTimeInterval = 5
  
  /// Specifies the speed in meters per second, when location 
  /// must be updated with updateLocationTimeInterval property.
  /// 
  /// Examples:
  /// 
  /// - 0       Stand
  /// - 0.3 - 1.38   Walk
  /// - 1.38 - 4.16   Run
  /// - 4.16 - 11.1  Bicycle
  ///
  var updateLocationSpeed: CLLocationSpeed = 0.0
  
  /// Specifies the minimum update time intervar in secounds.
  /// Even if core manger of other object will receive new location.
  ///
  /// Follow delegate method:
  ///
  ///     func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation)
  ///
  /// will run not less when n secounds delay after prevoius
  ///
  var updateLocationMinTimeInterval: NSTimeInterval = 2.0
  
  /// Specifies the max update time intervar in secounds. If updateLocationSpeed proretry have
  /// not zero value, but location manager can't detect speed.
  ///
  /// Follow delegate method:
  ///
  ///     func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation)
  ///
  /// will run after n secounds delay.
  ///
  var updateLocationMaxTimeInterval: NSTimeInterval = 300.0
  
  /// Specifies the time interval in secounds when class will try to
  /// get first location. If location undefined and timer is off,
  /// class will return error .LocationManagerCantDetectFirstLocation from error delegate method:
  ///
  ///     func locationManager(manager: AKLocationManager, didGetError error: AKLocationManagerError)
  ///
  var ditectFirsLocationTime: Int = 5
  
  //  MARK: Properties
  
  weak var delegate: AKLocationManagerDelegate?
  
  /// Core Location manager
  /// Can be initialized with custom properties
  ///
  var locationManager: CLLocationManager?
  
  /// Return location from Core Location manager
  ///
  var myLocation: CLLocation? {
    return locationManager?.location
  }

  //  MARK: Private Properties
  
  /// Using to detecting current speed
  ///
  private var previousMyLocation: CLLocation!
  
  private var totalDistance: CLLocationDistance = 0.0
  private var measureStartLocation: CLLocation!
  private var measureDistance: CLLocationDistance!
  
  private var observerObject: AnyObject!
  private var observerKeyPath: String!
  private var observerAdded: Bool = false
  
  /// This property using to detect if user manually change authorization status
  ///
  private var authorizationNotDetermined: Bool = false
  private var authorizationAllowed: Bool = false
  private var authorizationDenied: Bool = false
  private var authorizationStatus: CLAuthorizationStatus {
    return CLLocationManager.authorizationStatus()
  }
  private var isAuthorized: Bool {
    return authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse
  }
  
  //  Timers
  
  private var firstLocationTimer: NSTimer?
  private var firstLocation: Bool = false
  private var firstLocationCounter: Int = 0
  
  private var loopUpdateLocationTimer: NSTimer?
//  private var loopUpdateLocationTimeInterval: NSTimeInterval 
  
  private var updateLocationTimer: NSTimer?
  private var updateLocationTimeInterval: NSTimeInterval!
  private var updateLocationTimerFirstDelegate: Bool = false
  
  //  Other
  
  /// This property (flag) is used to prevent loops execution method name
  ///
  private var _startSafeUpdatingLocation: Bool = false
  
  /// This property (flag) is used to prevent loops execution method name
  ///
  private var  _addResignActiveObservers: Bool = false
  
  private var updateLocationStarted: Bool = false
  
  /// Key to detect current class "Background" state.
  /// Used to stop / start updatig locations if allowUpdateLocationInBackground setting set to true
  ///
  private var inBackground: Bool = false

  //  MARK: - Methods

  func requestForUpdatingLocation() {
    #if AKLocationManagerDEBUG
      print("\(self.dynamicType) \(#function) \n")
    #endif    
    
    //  CLLocationManager initalization.
    //  Initalization will call requestWhenInUseAuthorization() method automatically
    
    if locationManager == nil {
      locationManager = CLLocationManager()
      locationManager?.delegate = self
      locationManager?.desiredAccuracy = kCLLocationAccuracyBest
      locationManager?.activityType = .Fitness
      locationManager?.distanceFilter = 1
    }
    
    //  Prevent authorization if class already authorized
    //
    guard !isAuthorized else { return }
    locationManager?.requestWhenInUseAuthorization()
  }
  
  func startUpdatingLocation() {
    #if AKLocationManagerDEBUG
      print("\(self.dynamicType) \(#function) \n")
    #endif
    
    //  Global flag to detect if startUpdatingLocation method was called
    //
    updateLocationStarted = true
    
    guard isAuthorized else {
      delegate?.locationManager(self,
                                didGetNotification: .LocationManagerNotAuthorized)
      return
    }
    
    //  Manually reset first location counter when user call this method again
    //
    if firstLocationCounter != 0 { firstLocationCounter = 0 }
    
    //  START
    //
    _startSafeUpdatingLocation = false
    startSafeUpdatingLocation()
  }
  
  func startUpdatingLocationWithRequest() {
    requestForUpdatingLocation()
    startUpdatingLocation()
  }
  
  func stopUpdatingLocation() {
    #if AKLocationManagerDEBUG
      print("\(self.dynamicType) \(#function) \n")
    #endif
    
    //  STOP
    //
    updateLocationStarted = false
    stopSafeUpdatingLocation()
  }
  
  func updateLocation() {
    guard let location = myLocation else { return }
    
    locationTimersReset()
    
    // Manual update location
    //
    updateLocation(location)
  }
  
  func addObserver(target: AnyObject, forKeyPath: String) {
    observerObject = target
    observerKeyPath = forKeyPath
  }
  
  func removeObserver() {
    guard observerAdded else { return }
    
    observerObject?.removeObserver(self, forKeyPath: observerKeyPath)
    
    observerObject = nil
    observerKeyPath = nil
    observerAdded = false
  }
  
  func resetSettings() {
    allowUpdateLocationInBackground = false
    loopLocationTimeInterval = 5
    updateLocationTimeInterval = 2
//    minimumUpdateDistance = 50
//    incleaseUpdatedDistanceOnSpeedChange = false
    ditectFirsLocationTime = 5
  }
  
  func destroy() {
    //  1. Background notiications
    //
    NSNotificationCenter.defaultCenter().removeObserver(self)
    _addResignActiveObservers = false
    
    //  2.1. CLLocationManager
    //  2.2. Object
    //  2.3.a Location timers
    //
    inBackground = false
    stopSafeUpdatingLocation()
    
    //  2.3.b First location timer
    //
    firstLocationTimerReset()
    
    //  3. Rest object data
    //
    observerObject = nil
    observerKeyPath = nil
    
    //  4. Manager
    //
    locationManager = nil
    
    //  5. Settings
    //
    resetSettings()
  }
  
  //  MARK: - Pivate methods
  
  private func startSafeUpdatingLocation() {
    func start() {
      #if AKLocationManagerDEBUG
        print("\(self.dynamicType) \(#function) \n")
      #endif
      
      guard updateLocationStarted && !_startSafeUpdatingLocation else { return }
      _startSafeUpdatingLocation = true
      
      //  START
      //  1. CLLocationManager
      //
      locationManager?.startUpdatingLocation()

      //  2. Object
      //
      if observerObject != nil && !observerAdded {
        observerObject?.addObserver(self, forKeyPath: observerKeyPath, options: NSKeyValueObservingOptions.New, context: nil)
        observerAdded = true
      }
      //  3. Timers
      //  3.a First location
      //  3.b Loop location
      //
      locationTimersStart()
    }
    
    guard isAuthorized else { return }
    
    if inBackground {
      if allowUpdateLocationInBackground { start() }
    } else { start() }
  }
  
  private func stopSafeUpdatingLocation() {
    func stop() {
      #if AKLocationManagerDEBUG
        print("\(self.dynamicType) \(#function) \n")
      #endif

      _startSafeUpdatingLocation = false
      
      //  STOP
      //  1. CLLocationManager
      //
      locationManager?.stopUpdatingLocation()
      
      //  2. Object
      //
      if observerAdded {
        observerObject?.removeObserver(self, forKeyPath: observerKeyPath)
        observerAdded = false
      }
      
      //  3. Timers
      //  3.a First location
      //  3.b Loop location
      //
      locationTimersReset()
    }
    
    if inBackground {
      if !allowUpdateLocationInBackground { stop() }
    } else { stop() }
  }
  
  /// Reset updateLocationTimer and loopUpdateLocationTimer
  ///
  private func locationTimersReset() {
    
    //   Update with time interval timer
    //
    updateLocationTimerReset()
    
    //   Loop timer
    //
    loopUpdateLocationTimerReset()
  }

  private func updateLocation(location: CLLocation) {
    
    //  Update
    //
    delegate?.locationManager(self,
                              didUpdateLocation: location)
    
    //  Update after time interval and speed
    //
    
    
//    print("location \(location)")
    
    
    var timeInterval = updateLocationMinTimeInterval
    
    if location.speed >= updateLocationSpeed && location.speed != 0.0 {
      if updateLocationTimeInterval == updateLocationMaxTimeInterval {
        if let updateLocationTimerRemain = updateLocationTimer?.fireDate.timeIntervalSinceDate(NSDate()) {
          if updateLocationMaxTimeInterval - updateLocationTimerRemain > updateLocationMinTimeInterval {
            updateLocationTimerReset()
          }
        }
      }
    } else {
      timeInterval = updateLocationMaxTimeInterval
    }
    
    print("timeInterval \(timeInterval)")
    print("updateLocationTimer \(updateLocationTimeInterval)")
    
    updateLocationTimerStart(timeInterval)
    
  }

  private func addResignActiveObservers() {
    if !_addResignActiveObservers {
      let nc = NSNotificationCenter.defaultCenter()
      nc.addObserver(self,
                     selector:#selector(appWillResignActiveNotification),
                     name:UIApplicationWillResignActiveNotification,
                     object:nil)
      nc.addObserver(self,
                     selector:#selector(appDidBecomeActiveNotification),
                     name:UIApplicationDidBecomeActiveNotification,
                     object:nil)
      _addResignActiveObservers = true
    }
  }
  
  //  MARK: - Timers
  //  MARK:   Update location
  
  private func updateLocationTimerStart(timeInterval: NSTimeInterval) {
    if updateLocationTimer == nil {
      #if AKLocationManagerDEBUG
        print("\(self.dynamicType) \(#function) \n")
      #endif
      
      updateLocationTimeInterval = timeInterval
      updateLocationTimer = NSTimer.scheduledTimerWithTimeInterval(timeInterval,
                                                                   target: self,
                                                                   selector: #selector(updateLocationTimerReset),
                                                                   userInfo: nil,
                                                                   repeats: false)
      
      if updateLocationTimerFirstDelegate {
        delegate?.locationManager(self, didUpdateLocation: myLocation!, afterTimeInterval: updateLocationTimeInterval)
      }
      updateLocationTimerFirstDelegate = true
    }
  }
  
  @objc private func updateLocationTimerReset() {
    updateLocationTimer?.invalidate()
    updateLocationTimer = nil
  }
  
  //  MARK:   Update location with loop
  
  private func loopUpdateLocationTimerStart() {
    if loopUpdateLocationTimer == nil {
      #if AKLocationManagerDEBUG
        print("\(self.dynamicType) \(#function) \n")
      #endif
      
      loopUpdateLocationTimer = NSTimer.scheduledTimerWithTimeInterval(loopLocationTimeInterval,
                                                                 target: self,
                                                                 selector: #selector(loopUpdateLocationTimerAction),
                                                                 userInfo: nil,
                                                                 repeats: true)
    }
  }
  
  @objc private func loopUpdateLocationTimerAction() {
    delegate?.locationManager(self,
                              didUpdateLocation: myLocation,
                              inLoopModeAfterTimeInterval: loopLocationTimeInterval)
  }
  
  private func loopUpdateLocationTimerReset() {
    loopUpdateLocationTimer?.invalidate()
    loopUpdateLocationTimer = nil
  }
  
  //  MARK:   First location
  
  private func locationTimersStart() {
    if !firstLocation && firstLocationTimer == nil {
      #if AKLocationManagerDEBUG
        print("\(self.dynamicType) \(#function) \n")
      #endif
      
      firstLocationTimer = NSTimer.scheduledTimerWithTimeInterval(1,
                                                                  target: self,
                                                                  selector: #selector(firstLocationTimerAction),
                                                                  userInfo: nil,
                                                                  repeats: true)
      firstLocationTimerAction()
    }
    
    loopUpdateLocationTimerStart()
  }
  
  @objc private func firstLocationTimerAction() {
    if !firstLocation {
      if let myLocation = myLocation {

        delegate?.locationManager(self,
                                  didGetFirstLocation: myLocation)
        
        firstLocation = true
        firstLocationTimerReset()
        
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
  
  //  MARK: - Check authorization
  
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
  
  //  MARK: - Life cycle
  
  deinit { print("deinit \(self.dynamicType)") }
}

//  MARK: - CLLocationManagerDelegate

extension AKLocationManager: CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    switch status {
    case .AuthorizedAlways,
         .AuthorizedWhenInUse:
      
      if authorizationNotDetermined || inBackground {
        delegate?.locationManager(self,
                                  didGetNotification: .UserAllowedAuthorization)
      }
      
      if !authorizationAllowed {
        delegate?.locationManager(self,
                                  didGetNotification: .AuthorizationAllowed)
        
        authorizationDenied = false
        authorizationAllowed = true
      }
      
      startSafeUpdatingLocation()
      addResignActiveObservers()
      
    case .NotDetermined:
      authorizationNotDetermined = true
      
    case .Denied:

      stopSafeUpdatingLocation()
      
      if authorizationNotDetermined || inBackground {
        delegate?.locationManager(self,
                                  didGetNotification: .UserDeniedAuthorization)
      }
      
      if !authorizationDenied {
        delegate?.locationManager(self,
                                  didGetNotification: .AuthorizationDenied)
        
        authorizationDenied = true
        authorizationAllowed = false
      }
      addResignActiveObservers()
      
    case .Restricted: ()
    }
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.first else { return }
    
    //  Update
    //
    updateLocation(location)
  }
}

//  MARK: - Custom location Observer

extension AKLocationManager {
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if let keyPath = keyPath where keyPath == "myLocation" {
      guard let location = change![NSKeyValueChangeNewKey] as? CLLocation else { return }
      
      //  Update
      //
      updateLocation(location)
    }
  }
}

//  MARK: - Background Observer

extension AKLocationManager {
  func appWillResignActiveNotification() {
    #if AKLocationManagerDEBUG
      print("\(self.dynamicType) \(#function)")
    #endif
    
    inBackground = true
    stopSafeUpdatingLocation()
    delegate?.locationManager(self,
                              didGetNotification: .GoToBackground)
  }
  
  func appDidBecomeActiveNotification() {
    guard inBackground else { return }
    #if AKLocationManagerDEBUG
      print("\(self.dynamicType) \(#function)")
    #endif
    
    inBackground = false
    startSafeUpdatingLocation()
    delegate?.locationManager(self,
                              didGetNotification: .BackFromBackground)
  }
}