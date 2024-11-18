import Flutter
import CoreLocation

public class LocationPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, CLLocationManagerDelegate {
    private var eventSink: FlutterEventSink?
    private let locationManager = CLLocationManager()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "location_channel", binaryMessenger: registrar.messenger())
        let instance = LocationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(name: "location_stream", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }
    
    public override init() {
        super.init()
        locationManager.requestWhenInUseAuthorization()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        locationManager.stopUpdatingLocation()
        self.eventSink = nil
        return nil
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let horizontalAccuracy = location.horizontalAccuracy // 위치의 수평 정확도
            let time = location.timestamp.timeIntervalSince1970
            // print("Latitude: \(latitude), Longitude: \(longitude), Horizontal Accuracy: \(horizontalAccuracy), Time: \(time)")
            let locationData = ["latitude": latitude, "longitude": longitude, "horizontalAccuracy": horizontalAccuracy, "time": time] as [String : Any]
            self.eventSink?(locationData)
        }
    }
}

// 수정 후(5/30c_g)
// import Flutter
// import CoreLocation

// public class LocationPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, CLLocationManagerDelegate {
//     private var eventSink: FlutterEventSink?
//     private let locationManager = CLLocationManager()

//     public static func register(with registrar: FlutterPluginRegistrar) {
//         let eventChannel = FlutterEventChannel(name: "location_stream", binaryMessenger: registrar.messenger())
//         let instance = LocationPlugin()
//         eventChannel.setStreamHandler(instance)
//     }
    
//     public override init() {
//         super.init()
//         locationManager.requestWhenInUseAuthorization()
//     }

//     public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
//         self.eventSink = events
//         locationManager.delegate = self
//         locationManager.desiredAccuracy = kCLLocationAccuracyBest
//         locationManager.startUpdatingLocation()
//         return nil
//     }

//     public func onCancel(withArguments arguments: Any?) -> FlutterError? {
//         locationManager.stopUpdatingLocation()
//         self.eventSink = nil
//         return nil
//     }

//     public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//         if let location = locations.last {
//             let latitude = location.coordinate.latitude
//             let longitude = location.coordinate.longitude
//             let horizontalAccuracy = location.horizontalAccuracy
//             let time = location.timestamp.timeIntervalSince1970
//             print("Latitude: \(latitude), Longitude: \(longitude), Horizontal Accuracy: \(horizontalAccuracy), Time: \(time)")
//             let locationData = ["latitude": latitude, "longitude": longitude, "horizontalAccuracy": horizontalAccuracy, "time": time] as [String : Any]
//             self.eventSink?(locationData)
//         }
//     }
// }
