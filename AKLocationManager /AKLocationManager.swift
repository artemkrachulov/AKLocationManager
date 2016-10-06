//
//  AKLocationManager.swift
//
//  Created by Artem Krachulov
//  Copyright (c) 2016 Artem Krachulov. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
// v. 0.1
//

import CoreLocation
import UIKit

//  MARK: - AKLocationManagerNotification

enum AKLocationManagerNotification {
  /// Notification returns when you start  starts the generation of updates but location manager not authorized.
  case LocationManagerNotAuthorized
  /// Notification returns when user denied generation of location updates in device Settings (select Never).
  case AuthorizationDenied
  /// Notification returns when user allowed generation of location updates in device Settings (select Always).
  case AuthorizedAlways
  /// Notification returns when user allowed generation of location updates in device Settings (select While Using the App).
  case AuthorizedWhenInUse
  /// Notification returns when location manager detect changing authorization status.
  case UserAuthorizationDenied
  /// Notification returns when location manager detect changing authorization status.
  case UserAuthorizedAlways
  /// Notification returns when location manager detect changing authorization status.
  case UserAuthorizedWhenInUse
  /// Notification returns when the app is no longer active and loses focus.
  case AppInBackground
  /// Notification returns when the app becomes active.
  case AppActive
}

//  MARK: - AKLocationManagerError

enum AKLocationManagerError: ErrorType {
  /// Error returns when ditectFirsLocationTimer time is off.
  case LocationManagerCantDetectFirstLocation
}

//  MARK: - AKLocationManagerRequestType

enum AKLocationManagerRequestType {
  ///  Equal `requestWhenInUseAuthorization()` method.
  case WhenInUse
  ///  Equal `requestAlwaysAuthorization()` method.
  case Always
}

public class AKLocationManager: NSObject {
  
  //  MARK: Configurate
  
  /// Specifies the speed in meters per second, when location must be updated not less that updateLocationTimeInterval minimum property.
  ///
  /// Examples:
  ///
  /// - 0 : Stand
  /// - 0.3 - 1.4 : Walk
  /// - 1.4 - 4 : Run
  /// - 4 - 12 : Bicycle
  ///
  /// The initial value of this property is `0.4` meters per second. Walk.
  final var updateSpeed: CLLocationSpeed = 0.4
  
  /// Specifies the minimum and maximum update time intervar in secounds.
  ///
  /// Updating location will be no earlier than minimum time interval value with condition: "current speed more or equal to updateSpeed property and not equal zero". But if the condition is not satisfied, updating location will be no earlier than maximum time interval value.
  ///
  /// The initial value of this property is `5.0` seconds for minimum time interval and `300.0` seconds for maximum.
  final var updateLocationTimeInterval = AKLocationManagerTimeInterval(min: 5.0, max: 300.0)
  
  /// Specifies the count of attempts when location manager will try to get first location. One attempt every second. When all attempts is over, location manager will return error '.LocationManagerCantDetectFirstLocation' with error protocol method:
  ///
  ///     func locationManager(manager: AKLocationManager, didGetError error: AKLocationManagerError)
  /// The initial value of this property is `5` attempts.
  final var firstLocationAttempts: Int = 5
  
  //  MARK: Accessing the Delegate
  
  /// The delegate object to receive update events.
  weak var delegate: AKLocationManagerDelegate?
  
  /// Core location manager. Can be initialized with custom properties.
  /// The initial value of this property is `nil`
  final var locationManager: CLLocationManager?
  
  //  MARK: - Getting Recently Retrieved Data
  
  /// The most recently retrieved user location. (read-only). The value of this property is 'nil' if no location data has ever been retrieved.
  final var myLocation: CLLocation? {
    return locationManager?.location
  }
  
  //  MARK: Private Properties
  
  // Custom location manager
  private var observerObject: AnyObject!
  private var observerKeyPath: String!
  private var observerAdded: Bool = false
  
  // App authorized states. Using for detect manually changing authorization status by user.
  private var authNotDetermined: Bool = false
  var authorizationStatus: CLAuthorizationStatus { return CLLocationManager.authorizationStatus() }
  var isAuthorized: Bool {
    return authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse
  }
  
  //  Timers
  
  private var firstTimer: NSTimer?
  private var firstLocation: Bool = false
  private var firstLocationAttemptsCounter: Int = 0
  
  private var lastLocationDate: NSDate!
  
  //  Other
  
  /// This property (flag) is used to prevent loops execution method name
  private var _startSafeUpdatingLocation: Bool = false
  
  //
  private var _startSafeUpdatingLocationFirst: Bool = false
  
  /// This property (flag) is used to prevent loops execution method name
  private var  _addResignActiveObservers: Bool = false
  
  /// Specifies if startUpdatingLocation() or startUpdatingLocationWithRequest() was called.
  private var updateLocationStarted: Bool = false
  
  /// Key to detect current if app in background. Used to stop / start updatig locations if updatingInBackground setting set to true.
  private var inBackground: Bool = false
  
  override init() {
    super.init()
    initLocationManager()
  }
  
  final func initLocationManager() {
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    locationManager?.activityType = .Fitness
    locationManager?.distanceFilter = 1
  }
  
  //  MARK: - Requesting Authorization for Location Services
  
  /// Requests permission to use location services.
  final func requestForUpdatingLocation(requestType: AKLocationManagerRequestType = .WhenInUse) {
    #if AKLocationManagerDEBUG
      print("\(self.dynamicType) \(#function) \n")
    #endif
    
    // CLLocationManager initalization.
    // Initalization will call requestWhenInUseAuthorization() method automatically
    
    // Prevent authorization if class already authorized
    guard !isAuthorized else {
      
      if requestType == .WhenInUse && authorizationStatus != .AuthorizedWhenInUse {
        locationManager?.requestWhenInUseAuthorization()
      }
      if requestType == .Always && authorizationStatus != .AuthorizedAlways {
        locationManager?.requestAlwaysAuthorization()
      }
      return
    }
    
    if requestType == .WhenInUse {
      locationManager?.requestWhenInUseAuthorization()
    } else {
      locationManager?.requestAlwaysAuthorization()
    }
  }
  
  //  MARK: - Initiating Standard Location Updates
  
  /// Starts the generation of updates that report the user’s current location.
  func startUpdatingLocation() {
    #if AKLocationManagerDEBUG
      print("\(self.dynamicType) \(#function) \n")
    #endif
    
    updateLocationStarted = true
    
    guard isAuthorized else {
      delegate?.locationManager(self,
                                didGetNotification: .LocationManagerNotAuthorized)
      return
    }
    
    // Reset first location counter if this method called again
    if firstLocationAttemptsCounter != 0 { firstLocationAttemptsCounter = 0 }
    
    // START
    _startSafeUpdatingLocation = false
    startSafeUpdatingLocation()
  }
  
  /// Starts the generation of updates that report the user’s current location with requests permission to use location services.
  final func startUpdatingLocationWithRequest(requestType: AKLocationManagerRequestType = .WhenInUse) {
    requestForUpdatingLocation(requestType)
    startUpdatingLocation()
  }
  
  /// Stops the generation of location updates.
  final func stopUpdatingLocation() {
    #if AKLocationManagerDEBUG
      print("\(self.dynamicType) \(#function) \n")
    #endif
    
    // STOP
    updateLocationStarted = false
    stopSafeUpdatingLocation()
  }
  
  /// Request the one-time delivery of the user’s current location.
  final func requestLocation() {
    updateLocation(myLocation, skipSpeed: true)
  }
  
  //  MARK: Custom location manager
  
  /// Registers anObserver to receive KVO notifications for the specified key-path relative to the receiver.
  ///
  /// - Parameter target : The object to register for KVO notifications.
  /// - Parameter keyPath : The key path, relative to the receiver, of the property to observe. This value must not be nil.
  final func addObserver(target: AnyObject, forKeyPath keyPath: String) {
    observerObject = target
    observerKeyPath = keyPath
  }
  
  /// Stops a given object from receiving change notifications for the property specified by a given key-path relative to the receiver.
  final func removeObserver() {
    guard observerAdded else { return }
    
    observerObject?.removeObserver(self, forKeyPath: observerKeyPath)
    
    observerObject = nil
    observerKeyPath = nil
    observerAdded = false
  }
  
  /// Destroy location manager with add observers and timers.
  final func destroy() {
    
    // 1. Background notiications
    removeResignActiveObservers()
    
    // 2.1. CLLocationManager
    // 2.2. Object
    // 2.3.a Location timers
    inBackground = false
    stopSafeUpdatingLocation()
    
    // 2.3.b First location timer
    firstTimerReset()
    
    // 3. Rest object data
    observerObject = nil
    observerKeyPath = nil
    
    // 4. Manager
    locationManager = nil
  }
  
  //  MARK: - Pivate methods
  
  private func startSafeUpdatingLocation() {
    func start() {
      #if AKLocationManagerDEBUG
       print("\(self.dynamicType) \(#function) \n")
      #endif
      
      guard updateLocationStarted && !_startSafeUpdatingLocation else { return }
      _startSafeUpdatingLocation = true
      
      // START
      if firstLocation {
        _startSafeUpdatingLocationFirst = true
      }
      // 1. CLLocationManager
      locationManager?.startUpdatingLocation()
      
      // 2. Object
      if observerObject != nil && !observerAdded {
        observerObject?.addObserver(self, forKeyPath: observerKeyPath, options: NSKeyValueObservingOptions.New, context: nil)
        updateLocation(myLocation)
        observerAdded = true
      }
      
      // First location timers
      if !firstLocation && firstTimer == nil {
        #if AKLocationManagerDEBUG
          print("\(self.dynamicType) \(#function) \n")
        #endif
        
        firstTimer = NSTimer.scheduledTimerWithTimeInterval(1,
                                                            target: self,
                                                            selector: #selector(firstTimerAction),
                                                            userInfo: nil,
                                                            repeats: true)
        firstTimerAction()
      }
    }
    
    guard isAuthorized else { return }
    start()
  }
  
  private func stopSafeUpdatingLocation() {
    func stop() {
      #if AKLocationManagerDEBUG
        print("\(self.dynamicType) \(#function) \n")
      #endif
      
      _startSafeUpdatingLocation = false
      
      // STOP
      
      // 1. CLLocationManager
      locationManager?.stopUpdatingLocation()
      
      // 2. Object
      if observerAdded {
        observerObject?.removeObserver(self, forKeyPath: observerKeyPath)
        observerAdded = false
      }
      
      // 3. Timers
      // 3.a First location
      firstTimerReset()
    }
    
    stop()
  }
  
  private func updateLocation(location: CLLocation?, skipSpeed: Bool = false) {
    
    guard let location = myLocation else { return }
    
    // Update
    delegate?.locationManager(self,
                              didUpdateLocation: location)
    
    if skipSpeed || _startSafeUpdatingLocationFirst {
      let timeInterval = lastLocationDate != nil ? NSDate().timeIntervalSinceDate(lastLocationDate) : 0
      delegate?.locationManager(self, didUpdateLocation: location, afterTimeInterval: timeInterval)
      
      self.lastLocationDate = NSDate()
      _startSafeUpdatingLocationFirst = false
      return
    }
    
    guard let lastLocationDate = lastLocationDate else {
      self.lastLocationDate = NSDate()
      return
    }
    
    var timeInterval = updateLocationTimeInterval.max
    
    if location.speed >= updateSpeed && location.speed > 0.0 {
      timeInterval = updateLocationTimeInterval.min
    }
    
    if NSDate().timeIntervalSinceDate(lastLocationDate) > timeInterval {
      self.lastLocationDate = NSDate()
      delegate?.locationManager(self, didUpdateLocation: location, afterTimeInterval: timeInterval)
    }
  }
  
  //  MARK: - Timers
  
  //  MARK: First location
  
  @objc private func firstTimerAction() {
    if !firstLocation {
      if let myLocation = myLocation {
        
        delegate?.locationManager(self,
                                  didGetFirstLocation: myLocation)
        
        firstLocation = true
        firstTimerReset()
      } else {
        
        firstLocationAttemptsCounter += 1
        while firstLocationAttemptsCounter == firstLocationAttempts {
          
          delegate?.locationManager(self,
                                    didGetError: .LocationManagerCantDetectFirstLocation)
          return
        }
      }
    }
  }
  
  private func firstTimerReset() {
    firstTimer?.invalidate()
    firstTimer = nil
  }
  
  //  MARK: - Check authorization
 
  final func locationAccessNotAuthorized(onComplete: (locationServicesEnabled: Bool, authorizationStatus: CLAuthorizationStatus) -> ()) {
    onComplete(locationServicesEnabled:
      CLLocationManager.locationServicesEnabled(), authorizationStatus: authorizationStatus)
  }
  
  final func locationAccessDenied(onComplete: (locationServicesEnabled: Bool) -> ()) {
    if authorizationStatus == .Denied {
      onComplete(locationServicesEnabled:
        CLLocationManager.locationServicesEnabled())
    }
  }
  
  final func locationAccessRestricted(onComplete: (locationServicesEnabled: Bool) -> ()) {
    if authorizationStatus == .Restricted {
      onComplete(locationServicesEnabled:
        CLLocationManager.locationServicesEnabled())
    }
  }
  
  final func locationAccessNotDetermined(onComplete: (locationServicesEnabled: Bool) -> ()) {
    if authorizationStatus == .NotDetermined {
      onComplete(locationServicesEnabled:
        CLLocationManager.locationServicesEnabled())
    }
  }
  
  //  MARK: - Life cycle
  
  deinit {
    removeResignActiveObservers()
    removeObserver()
    print("deinit \(self.dynamicType)")
  }
}

//  MARK: - CLLocationManagerDelegate

extension AKLocationManager: CLLocationManagerDelegate {
  public func locationManager(manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .AuthorizedAlways,
         .AuthorizedWhenInUse:
      
      if authNotDetermined {
        delegate?.locationManager(self,
                                  didGetNotification: (status == .AuthorizedAlways) ? .UserAuthorizedAlways : .UserAuthorizedWhenInUse)
      }
      
      delegate?.locationManager(self,
                                didGetNotification: (status == .AuthorizedAlways) ? .AuthorizedAlways : .AuthorizedWhenInUse)
      
      startSafeUpdatingLocation()
      addResignActiveObservers()
      
    case .NotDetermined:
      authNotDetermined = true
    case .Denied:
      
      stopSafeUpdatingLocation()
      
      if authNotDetermined {
        delegate?.locationManager(self,
                                  didGetNotification: .UserAuthorizationDenied)
      }
      
      delegate?.locationManager(self,
                                didGetNotification: .AuthorizationDenied)
      
      removeResignActiveObservers()
    case .Restricted: ()
    }
  }
  
  public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard observerObject == nil && observerKeyPath == nil else { return }
    updateLocation(locations.first)
  }
}

//  MARK: - Custom location Observer

extension AKLocationManager {
  override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if let keyPath = keyPath where keyPath == "myLocation" {
      updateLocation(change![NSKeyValueChangeNewKey] as? CLLocation)
    }
  }
}

//  MARK: - Background Observer

extension AKLocationManager {
  
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
  
  private func removeResignActiveObservers() {
    NSNotificationCenter.defaultCenter().removeObserver(self)
    _addResignActiveObservers = false
  }
  
  @objc private func appWillResignActiveNotification() {
    #if AKLocationManagerDEBUG
      print("\(self.dynamicType) \(#function)")
    #endif
    
    inBackground = true
    delegate?.locationManager(self,
                              didGetNotification: .AppInBackground)
  }
  
  @objc private func appDidBecomeActiveNotification() {
    guard inBackground else { return }
    #if AKLocationManagerDEBUG
      print("\(self.dynamicType) \(#function)")
    #endif
    
    inBackground = false
    updateLocation(myLocation, skipSpeed: true)
    delegate?.locationManager(self,
                              didGetNotification: .AppActive)
  }
}

//  MARK: - AKLocationManagerDelegate

protocol AKLocationManagerDelegate : class {
  
  /// Tells the delegate that fitst location data is received.
  ///
  /// - Parameter manager : The location manager object that generated the update event.
  /// - Parameter location :The most recently retrieved user location.
  func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation)
  
  /// Default sender of this method on core location manager. After registering observer (ex. Google Maps) sender will be custom location manager.
  ///
  /// - Parameter manager : The location manager object that generated the update event.
  /// - Parameter location :The most recently retrieved user location.
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation)
  
  /// Default sender of this method on core location manager. After registering observer (ex. Google Maps) sender will be custom location manager. Updating location will be no earlier than minimum or maximum time interval value.
  ///
  /// - Parameter manager : The location manager object that generated the update event.
  /// - Parameter location :The most recently retrieved user location.
  /// - Parameter timeInterval : Time interval value from since last update.
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterTimeInterval timeInterval: NSTimeInterval)
  
  /// Tells the delegate that the location manager was unable to retrieve a location value.
  ///
  /// - Parameter manager : The location manager object that generated the update event.
  /// - Parameter error : The error object containing the reason the location or heading could not be retrieved.
  func locationManager(manager: AKLocationManager, didGetError error: AKLocationManagerError)
  
  /// Tells the delegate that the location manager detect new notification.
  ///
  /// - Parameter manager : The location manager object that generated the update event.
  /// - Parameter notification : Current notification. Represents as `AKLocationManagerNotification` enumeration object.
  func locationManager(manager: AKLocationManager, didGetNotification notification: AKLocationManagerNotification)
}

extension AKLocationManagerDelegate {
  func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation) {}
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation) {}
  func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterTimeInterval timeInterval: NSTimeInterval) {}
  func locationManager(manager: AKLocationManager, didGetError error: AKLocationManagerError) {}
  func locationManager(manager: AKLocationManager, didGetNotification notification: AKLocationManagerNotification) {}
}
