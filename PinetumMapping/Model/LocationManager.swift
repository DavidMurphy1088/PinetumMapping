import Foundation
import CoreLocation
import MapKit

class Delta : NSObject, ObservableObject {
    var lat:Double
    var lng:Double
    init(lat:Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }
}

class Deltas : NSObject, ObservableObject {
    public var deltas:[Delta] = []
    @Published var deltaCnt = 0
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static public let shared = LocationManager()
    
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentHeading: CLLocationDirection?
    @Published var status: String?
    @Published var lastStableLocation: CLLocationCoordinate2D?
    @Published var deltas: Deltas = Deltas()
    
    public var requiredStability:Int = 5
    private let locationManager = CLLocationManager()
    private var locationReadCount = 0
    private var firstLocation: CLLocationCoordinate2D?
    private var lastLocation: CLLocationCoordinate2D?
    private var lastStableLocCounter:Int = 0
    
    override init() {
        super.init()
        locationManager.delegate = self

        switch locationManager.accuracyAuthorization {
        case .fullAccuracy:
            print("Full Accuracy")
        case .reducedAccuracy:
            print("Reduced Accuracy")
        @unknown default:
            print("Unknown Precise Location")
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func setStatus(_ msg: String) {
        DispatchQueue.main.async {
            self.status = msg
            if let loc = self.currentLocation {
                self.status! += "\nCurrent:" + String(String(format: "%.4f",loc.latitude) + ", "  + String(String(format: "%.4f",loc.longitude)))
            }
        }
    }
    
    func requestLocation() {
        self.setStatus("Requested Continous Locations")
        self.locationReadCount = 0
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        DispatchQueue.main.async { [self] in
            self.currentHeading = heading.magneticHeading
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        lastLocation = self.currentLocation
        currentLocation = location.coordinate
        locationReadCount += 1
        
        var delta:Double?
        if let last = lastLocation {
            if let cur = currentLocation {
                delta = distance(startLat: last.latitude, startLng: last.longitude,
                                         endLat: cur.latitude, endLng: cur.longitude)
                if delta != nil && delta!.isNaN {
                    delta = 0
                }
            }
        }
        if firstLocation == nil {
            firstLocation = currentLocation
        }
        
        var deltaStr = ""
        if let delta = delta {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.maximumFractionDigits = 1
            deltaStr = numberFormatter.string(from: NSNumber(value: delta)) ?? ""
            if delta < 1.0 { //todo
                lastStableLocCounter += 1
            }
            else {
                lastStableLocCounter = 0
            }
            if lastStableLocCounter >= self.requiredStability {
                lastStableLocation = currentLocation
            }
            else {
                self.lastStableLocation = nil
            }
        }
        
        DispatchQueue.main.async { [self] in
            if let current = currentLocation {
                let deltaFromFirst = Delta(lat: current.latitude - self.firstLocation!.latitude, lng: current.longitude - self.firstLocation!.longitude)
                if let delta = delta {
                    if delta > 1.0 {
                        self.deltas.deltas.append(deltaFromFirst)
                        self.deltas.deltaCnt += 1
                    }
                }
                print("New GPS ================", self.locationReadCount, self.deltas.deltas.count, currentLocation?.latitude, deltaFromFirst.lat)

            }
            self.setStatus("Count:\(self.locationReadCount) Delta:" + (deltaStr) + " Consec:" + String(lastStableLocCounter))
        }
    }
    
    public func resetLastStableLocation() {
        DispatchQueue.main.async {
            self.lastStableLocation = nil
            self.lastStableLocCounter = 0
        }
    }
        
    func reset() {
        locationReadCount = 0
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        currentLocation = nil
        lastLocation = nil
        lastStableLocCounter = 0
        lastStableLocation = nil
        self.setStatus("Reset Location Manager")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        setStatus("ERROR:"+error.localizedDescription)
    }
    
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
    func distance(startLat: Double, startLng:Double, endLat: Double, endLng:Double) -> Double {
        //=1000*ACOS(COS(RADIANS(90-C3))*COS(RADIANS(90-E3))+SIN(RADIANS(90-C3))*SIN(RADIANS(90-E3))*COS(RADIANS(D3-F3)))*6371

        var p1 = (-39.88588889,  175.9621667) // 90 metres cottage to gate
        var p2 = (-39.88597222,  175.9611111)
//        p1 = (-41.27847, 174.76829)
//        p2 = (-41.27853, 174.76849)
        p1 = (startLat, startLng)
        p2 = (endLat, endLng)
        
        var cx = 90 - p1.0
        cx = deg2rad(cx)
        cx = cos(cx)

        var cy = 90 - p2.0
        cy = deg2rad(cy)
        cy = cos(cy)

        var sx = 90 - p1.0
        sx = deg2rad(sx)
        sx = sin(sx)
        
        var sy = 90 - p2.0
        sy = deg2rad(sy)
        sy = sin(sy)
        
        var cz = p1.1 - p2.1
        cz = deg2rad(cz)
        cz = cos(cz)

        var r = (cx*cy) + (sx*sy*cz)
        r = acos(r)
        return r * 6371 * 1000
    }
    
}


