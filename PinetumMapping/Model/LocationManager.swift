import Foundation
import CoreLocation
import MapKit

class StableLocation {
    var latitude:Double
    var longitude:Double
    var ptType:Int
    
    init(lat:Double, lng: Double, ptType:Int) { //}, distance:Double) {
        self.latitude = lat
        self.longitude = lng
        self.ptType = ptType
    }
}

class StableLocations {
    public var locations:[StableLocation] = []
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static public let shared = LocationManager()
    
    @Published var currentHeading: CLLocationDirection?
    @Published var status: String?
    @Published var locationIsStable: Bool = false
    @Published var stableLocationsCount = 0

    public var displayLocations: [StableLocation] = []
    public var currentLocation: CLLocationCoordinate2D?
    public var bestLocation: CLLocationCoordinate2D? //average of all stable location GPS reads
    public var requiredStabilityCounter:Int = 4

    private let locationManager = CLLocationManager()
    private var stableLocations: StableLocations = StableLocations()
    private var locationReadCount = 0
    private var lastLocation: CLLocationCoordinate2D?
    private var stableLocCounter:Int = 0 //counts # of successive GPS readings that have not changed location much
    
    override init() {
        super.init()
        locationManager.delegate = self

        switch locationManager.accuracyAuthorization {
        case .fullAccuracy:
            self.setStatus("Full Accuracy")
        case .reducedAccuracy:
            self.setStatus("Reduced Accuracy")
        @unknown default:
            self.setStatus("Unknown Precise Location")
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func reset() {
        stableLocCounter = 0
        stableLocations.locations = []
        bestLocation = nil
        
        locationIsStable = false
        currentLocation = nil
        locationReadCount = 0
        lastLocation = nil
        
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        self.setStatus("Location Manager was reset")
    }

//    func getLastStableLocation() -> StableLocation? {
//        if stableLocations.locations.count > 0 {
//            return stableLocations.locations[stableLocations.locations.count - 1]
//        }
//        return nil
//    }

    private func setStatus(_ msg: String) {
        DispatchQueue.main.async {
            self.status = msg
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

    func locationManager(_ manager: CLLocationManager, didUpdateLocations GPSLocations: [CLLocation]) {
        guard let GPSLocation = GPSLocations.first else { return }
        lastLocation = currentLocation
        currentLocation = GPSLocation.coordinate
        locationReadCount += 1
        
        var deltaFromLast:Double?
        if let last = lastLocation {
            if let cur = currentLocation {
                deltaFromLast = distance(startLat: last.latitude, startLng: last.longitude,
                                         endLat: cur.latitude, endLng: cur.longitude)
                if deltaFromLast != nil && deltaFromLast!.isNaN {
                    deltaFromLast = 0
                }
            }
        }

        if let deltaFromLast = deltaFromLast {
            if deltaFromLast < 1.0 { //todo
                stableLocCounter += 1
            }
            else {
                stableLocCounter = 0
                return
            }
        }
        
        if stableLocCounter > self.requiredStabilityCounter {
            let location = StableLocation(lat: currentLocation!.latitude, lng: currentLocation!.longitude, ptType: 0)
            self.stableLocations.locations.append(location)
            stableLocCounter = 0
        }
        
        DispatchQueue.main.async { [self] in
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.maximumFractionDigits = 1
            let deltaStr = numberFormatter.string(from: NSNumber(value: deltaFromLast ?? 0)) ?? ""
            
            //display locations are relative to the 0 element
            self.displayLocations = []
            
            var avgDist = 0.0
            if self.stableLocations.locations.count > 0 {
                if self.stableLocations.locations.count == 1 {
                    self.displayLocations.append(StableLocation(lat: 0, lng: 0, ptType: 0))
                }
                else {
                    let firstLocation = self.stableLocations.locations[0]
                    var totLatitude = 0.0
                    var totLongitude = 0.0
                    var ctr = 0
                    for location in self.stableLocations.locations {
                        self.displayLocations.append(StableLocation(lat: location.latitude-firstLocation.latitude,
                                                                    lng: location.longitude-firstLocation.longitude,
                                                                    ptType: ctr == self.stableLocations.locations.count-1 ? 2 : 1))
                        totLatitude += location.latitude
                        totLongitude += location.longitude
                        ctr += 1
                    }
                    //add calculated center GPS reading location
                    let avgLatitude = totLatitude / Double(stableLocations.locations.count)
                    let avgLongitude = totLongitude / Double(stableLocations.locations.count)
                    self.bestLocation = CLLocationCoordinate2D(latitude: avgLatitude, longitude: avgLongitude)
                    //StableLocation(lat: avgLatitude, lng: avgLongitude, ptType: 0)
                    self.displayLocations.append(StableLocation(lat: avgLatitude - firstLocation.latitude,
                                                                lng: avgLongitude - firstLocation.longitude, ptType: 3))
                    //average distances from center
                    var totalDistance = 0.0
                    for location in self.stableLocations.locations {
                        let dist = self.distance(startLat: location.latitude, startLng: location.longitude,
                                                 endLat: self.bestLocation!.latitude, endLng: self.bestLocation!.longitude)
                        totalDistance += dist
                    }
                    avgDist = totalDistance / Double(self.stableLocations.locations.count)
                }
            }

            self.locationIsStable = self.stableLocations.locations.count > 0
            self.stableLocationsCount = self.stableLocations.locations.count
            //self.setStatus("Count:\(self.locationReadCount) Delta:" + (deltaStr) + " StableCtr:" + String(self.stableLocCounter) + " Dist:" + String(avgDist))
            self.setStatus("Count:\(self.locationReadCount) StableCtr:" + String(self.stableLocCounter) +
                           " Points:" + String(self.stableLocations.locations.count) +
                           " Dist:" + String(format: "%.1f", avgDist))
        }
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


