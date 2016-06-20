# AKLocationManager

Location manager class which can better controll your location.

## Features

* Detect first location.
* Updating locaiton with timers.
* Updating location when moving, disable when you stop.
* Connection Google Map location manager.
* Play / Pause updating locaiton.
* Better error management.

## Usage

### Standalone

```swift
var locationManager: AKLocationManager!

override func viewDidLoad() {
    super.viewDidLoad()

    locationManager = AKLocationManager()
    locationManager.startUpdatingLocationWithRequest()
}

override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    locationManager.stopUpdatingLocation()
}
```

### With google maps

```swift
var locationManager: AKLocationManager! {
    didSet { locationManager.delegate = self }
}
var mapView: GMSMapView!

//  MARK: - Life cycle

override func viewDidLoad() {
    super.viewDidLoad()

    locationManager = AKLocationManager()

    mapView = GMSMapView()
    mapView.alpha = 0
    mapView.frame = view.frame

    view.addSubview(mapView)
    view.sendSubviewToBack(mapView)

    locationManager.addObserver(mapView, forKeyPath: "myLocation")
    locationManager.requestForUpdatingLocation()
    mapView.myLocationEnabled = true
    locationManager.startUpdatingLocation()
}

override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    locationManager.stopUpdatingLocation()
}

//  MARK: - AKLocationManagerDelegate

extension DemoViewController: AKLocationManagerDelegate {
    func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation) {
        mapView.camera = GMSCameraPosition.cameraWithLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 12)
        mapView.alpha = 1
    }
}
```

> Before enable my location with `myLocationEnabled` property from `GMSMapView` class, call `requestForUpdatingLocation()` method.

---

## Requirements

- iOS 8.0+
- Xcode 7.3+

## Installation

1. Clone or download demo project.
2. Add `AKLocationManager ` folder to your project.

> Demo project require GoogleMaps pod. You need install pod with command `pod install`. Open `Demo.xcworkspace` file and past your api key `__API_KEY__`from Google Developers Console.

## Requesting Authorization for Location Services

```swift
func requestForUpdatingLocation(requestType: AKLocationManagerRequestType = default)
```

Requests permission to use location services.
Parameters:
* `requestType` : Request authorization type for Location Services. Represents as `AKLocationManagerRequestType`. Default value is `.WhenInUse`.

## Initiating Standard Location Updates

```swift
 func startUpdatingLocation()
```

Starts the generation of updates that report the user’s current location.

```swift
func startUpdatingLocationWithRequest(requestType: AKLocationManagerRequestType = default)
```

Starts the generation of updates that report the user’s current location with requests permission to use location services.
Parameters:
* `requestType` : Request authorization type for Location Services. Represents as `AKLocationManagerRequestType`. Default value is `.WhenInUse`.

```swift
 func stopUpdatingLocation()
```

Stops the generation of location updates.

```swift
func requestLocation()
```

Request the one-time delivery of the user’s current location.

## Observerving custom location manager

 ```swift
func addObserver(target: AnyObject, forKeyPath keyPath: String)
```

Registers an observer to receive KVO notifications for the specified key-path relative to the receiver.
Parameters:
- `target` : The object to register for KVO notifications.
- `keyPath` : The key path, relative to the receiver, of the property to observe. This value must not be nil.

 ```swift
func removeObserver()
```

Stops a given object from receiving change notifications for the property specified by a given key-path relative to the receiver.

## Getting Recently Retrieved Data

```swift
var myLocation: CLLocation? {get}
```

The most recently retrieved user location. (read-only). The value of this property is `nil` if no location data has ever been retrieved.

## Configurate

```swift
var updateSpeed: CLLocationSpeed
```

Specifies the speed in meters per second, when location must be updated not less that `updateLocationTimeInterval` minimum property.
Example:
- `0` : Stand
- `0.3 - 1.4` : Walk
- `1.4 - 4` : Run
-  `4 - 12` : Bicycle

The initial value of this property is `0.4` meters per second. Walk.

```swift
var updateLocationTimeInterval: AKLocationManagerTimeInterval
```

Specifies the minimum and maximum update time intervar in secounds. Updating location will be no earlier than minimum time interval value with condition: "current speed more or equal to updateSpeed property and not equal zero". But if the condition is not satisfied, updating location will be no earlier than maximum time interval value.
The initial value of this property is `5.0` seconds for minimum time interval and `300.0` seconds for maximum.

```swift
var firstLocationAttempts: Int
```

Specifies the count of attempts when location manager will try to get first location. One attempt every second. When all attempts is over, location manager will return error `.LocationManagerCantDetectFirstLocation` with error protocol method: `func locationManager(manager: AKLocationManager, didGetError error: AKLocationManagerError)`.
The initial value of this property is `5` attempts.

### Accessing the Delegate

```swift
weak var delegate: AKLocationManagerDelegate?
```

The delegate object to receive update events.

## AKLocationManagerDelegate

```swift
func locationManager(manager: AKLocationManager, didGetFirstLocation location: CLLocation)
```

Tells the delegate that fitst location data is received.

Parameters:
* `manager` : The location manager object that generated the update event.
* `location` :The most recently retrieved user location.

```swift
func locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation)
```

Tells the delegate that new location data is available. Default sender of this method on core location manager. After registering observer (ex. Google Maps) sender will be custom location manager.
Parameters:
* `manager` : The location manager object that generated the update event.
* `location` :The most recently retrieved user location.

```swift
locationManager(manager: AKLocationManager, didUpdateLocation location: CLLocation, afterTimeInterval timeInterval: NSTimeInterval?)
```

Default sender of this method on core location manager. After registering observer (ex. Google Maps) sender will be custom location manager. Updating location will be no earlier than minimum or maximum time interval value.
Parameters:
* `manager` : The location manager object that generated the update event.
* `location` :The most recently retrieved user location.
* `timeInterval` : Time interval value from since last update. Can be `nil` value on start updating location.

```swift
func locationManager(manager: AKLocationManager, didGetError error: AKLocationManagerError)
```

Tells the delegate that the location manager was unable to retrieve a location value.
Parameters:
* `manager` : The location manager object that generated the update event.
* `error` : The error object containing the reason the location or heading could not be retrieved. Represents as `AKLocationManagerError`.

```swift
func locationManager(manager: AKLocationManager, didGetNotification notification: AKLocationManagerNotification)
```

Tells the delegate that the location manager detect new notification.
Parameters:
* `manager` : The location manager object that generated the update event.
* `notification` : Current notification. Represents as `AKLocationManagerNotification` enumeration object.

## AKLocationManagerRequestType

```swift
enum AKLocationManagerRequestType {
    case WhenInUse
    case Always
}
```

Properties:
* `WhenInUse` : Equal `requestWhenInUseAuthorization()` method. Read more on [Apple Developer](https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/#//apple_ref/occ/instm/CLLocationManager/requestWhenInUseAuthorization)
* `Always` : Equal `requestAlwaysAuthorization()` method. Read more on [Apple Developer](https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/#//apple_ref/occ/instm/CLLocationManager/requestAlwaysAuthorization)

## AKLocationManagerError

```swift
enum AKLocationManagerError: ErrorType {
    case LocationManagerCantDetectFirstLocation
}
```

Properties:
* `LocationManagerCantDetectFirstLocation` : Error returns when location manager can't detect first location when all attempts is over.

## AKLocationManagerNotification

```swift
enum AKLocationManagerNotification {
    case LocationManagerNotAuthorized
    case UserAuthorizationDenied
    case UserAuthorizedAlways
    case UserAuthorizedWhenInUse
    case AuthorizationDenied
    case AuthorizedAlways
    case AuthorizedWhenInUse
    case AppInBackground
    case AppActive
}
```

Properties:
* `LocationManagerNotAuthorized` : Notification returns when you start  starts the generation of updates but location manager not authorized.
* `UserAuthorizationDenied` : Notification returns when user denied generation of location updates in device Settings (select Never).
* `UserAuthorizedAlways` : Notification returns when user allowed generation of location updates in device Settings (select Always).
* `UserAuthorizedWhenInUse` : Notification returns when user allowed generation of location updates in device Settings (select While Using the App).
* `AuthorizationDenied` : Notification returns when location manager detect changing authorization status.
* `AuthorizedAlways` : Notification returns when location manager detect changing authorization status.
* `AuthorizedWhenInUse` : Notification returns when location manager detect changing authorization status.
* `AppInBackground` : Notification returns when the app is no longer active and loses focus.
* `AppActive` : Notification returns when the app becomes active.

---

Please do not forget to ★ this repository to increases its visibility and encourages others to contribute.

### Author

Artem Krachulov: [www.artemkrachulov.com](http://www.artemkrachulov.com/)
Mail: [artem.krachulov@gmail.com](mailto:artem.krachulov@gmail.com)

### License

Released under the [MIT license](http://www.opensource.org/licenses/MIT)