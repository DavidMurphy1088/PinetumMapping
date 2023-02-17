import Foundation
import CoreLocation
import MapKit

class Delta : NSObject, ObservableObject {
    var lat:Double
    var lng:Double
    var ptType:Int
    var distance: Double
    
    init(lat:Double, lng: Double, ptType:Int, distance:Double) {
        self.lat = lat
        self.lng = lng
        self.ptType = ptType
        self.distance = distance
    }
}

class Deltas : NSObject, ObservableObject {
    public var deltas:[Delta] = []
    @Published var deltaCnt = 0
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static public let shared = LocationManager()
    
    @Published var currentHeading: CLLocationDirection?
    @Published var status: String?
    @Published var lastStableLocation: CLLocationCoordinate2D?
    @Published var firstStableLocation: CLLocationCoordinate2D?
    @Published var deltas: Deltas = Deltas()
    @Published var locationIsStable: Bool = false
    //@Published var centerPlotPoint: Delta = Delta(lat: 0, lng: 0, ptType: 0, distance: 0)

    private let locationManager = CLLocationManager()
    public var requiredStabilityCounter:Int = 4

    public var currentLocation: CLLocationCoordinate2D?
    private var locationReadCount = 0
    private var lastLocation: CLLocationCoordinate2D?
    private var stableLocCounter:Int = 0 //counts # of successive GPS readings that have not changed location much
    private var stableLocsCount = 0
    
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
    
    func reset() {
        stableLocCounter = 0
        lastStableLocation = nil
        firstStableLocation = nil
        deltas.deltas = []
        deltas.deltaCnt = 0
        locationIsStable = false
        currentLocation = nil
        locationReadCount = 0
        lastLocation = nil
        stableLocsCount = 0
        
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        self.setStatus("Location Manager was reset")
    }
    
    //public func resetLastStableLocation() {
    //        DispatchQueue.main.async {
    //            self.lastStableLocation = nil
    //            self.lastStableLocCounter = 0
    //        }
    //    }
    
    func maxDistance() -> Double {
        var max = 0.0
        for delta in deltas.deltas {
            if delta.distance > max {
                max = delta.distance
            }
        }
        return max
    }
    
    private func setStatus(_ msg: String) {
        DispatchQueue.main.async {
            self.status = msg
//            if let loc = self.currentLocation {
//                self.status! += "\nCurrent:" + String(String(format: "%.4f",loc.latitude) + ", "  + String(String(format: "%.4f",loc.longitude)))
//            }
            self.status! += "\nStables:\(self.stableLocsCount) Points:\(self.deltas.deltas.count) MaxDist:"
                + String(format: "%.1f",self.maxDistance())
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
        //TODO device accuracy see apple for 'precise location'
        //            //https://support.apple.com/en-nz/guide/iphone/iph3dd5f9be/ios
        //            }
        guard let location = locations.first else { return }
        lastLocation = self.currentLocation
        currentLocation = location.coordinate
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

        var plotPoint:Delta?
        var center:CLLocation?

        if let deltaFromLast = deltaFromLast {
            if deltaFromLast < 1.0 { //todo
                stableLocCounter += 1
            }
            else {
                stableLocCounter = 0
            }
            if stableLocCounter >= self.requiredStabilityCounter {
                stableLocsCount += 1
                if firstStableLocation == nil {
                    firstStableLocation = currentLocation
                    //add the plot center point
                    deltas.deltas.append(Delta(lat: 0, lng: 0, ptType: 1, distance: 0))
                    //deltas.deltas.append(Delta(lat: 0, lng: 0, ptType: 2, distance: 0))
                }
                else {
                    if let current = currentLocation {
                        //plot points generated as offsets from the first stable locationz
                        let distance = distance(startLat: current.latitude , startLng: current.longitude,
                                                endLat: firstStableLocation!.latitude, endLng: firstStableLocation!.longitude)
                        //if distance >= 0.0 {
                            plotPoint = Delta(lat: current.latitude - firstStableLocation!.latitude,
                                              lng: current.longitude - firstStableLocation!.longitude,
                                              ptType: 0, distance: distance)
                            if self.deltas.deltas.count > 1 {
                                var totLat = 0.0
                                var totLng = 0.0
                                for delta in self.deltas.deltas {
                                    totLng += delta.lat
                                    totLng += delta.lng
                                }
                                center = CLLocation(latitude: totLat/Double(deltas.deltas.count) - firstStableLocation!.latitude,
                                                             longitude: totLng/Double(deltas.deltas.count) - firstStableLocation!.longitude)
                            }
                        //}
                    }
                }
                lastStableLocation = currentLocation
                //wait for required successive close locations before setting another stable location
                stableLocCounter = 0
            }
        }
        
        DispatchQueue.main.async { [self] in
            var deltaStr = ""
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.maximumFractionDigits = 1
            deltaStr = numberFormatter.string(from: NSNumber(value: deltaFromLast ?? 0)) ?? ""
            if let plotPoint = plotPoint {
                self.deltas.deltas.append(plotPoint)
                self.deltas.deltaCnt += 1
                if let center = center {
                    //self.centerPlotPoint.lat = center.coordinate.latitude
                    //self.centerPlotPoint.lng = center.coordinate.longitude
                }
            }
            else {
                if self.deltas.deltas.count == 0 {
                    self.deltas.deltas.append(Delta(lat: 0, lng: 0, ptType: 1, distance: 0.0))
                    self.deltas.deltaCnt = self.deltas.deltas.count
                }
            }
            self.locationIsStable = self.lastStableLocation != nil
            self.setStatus("Count:\(self.locationReadCount) Delta:" + (deltaStr) + " Consec:" + String(self.stableLocCounter))
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


