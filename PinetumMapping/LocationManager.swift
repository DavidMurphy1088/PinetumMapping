import Foundation
import CoreLocation
import MapKit

class VisitRecord : Codable, Hashable {
    //:Encodable, Hashable, Comparable, ObservableObject {
    var deviceName:String
    var datetime:TimeInterval
    var latitude:Double
    var longitude:Double
    var bearing:Int
    
    init(deviceName:String, lat:Double, lng:Double) {
        self.deviceName = deviceName
        self.datetime = Date().timeIntervalSince1970
        self.latitude = lat
        self.longitude = lng
        self.bearing = 0
    }
    
    static func == (lhs: VisitRecord, rhs: VisitRecord) -> Bool {
        return lhs.datetime < rhs.datetime
    }
    
    static func < (lhs: VisitRecord, rhs: VisitRecord) -> Bool {
        return lhs.datetime < rhs.datetime
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(String(self.datetime))
    }
}

class LocationRecord : NSObject, Codable, Comparable, ObservableObject { //NSObject, Encodable, Decodable, Comparable, ObservableObject {
    public var visits : [VisitRecord] = []
    var deviceName:String
    var locationName:String
    var datetime:TimeInterval
    var spare:String
    var id:String
    
    init(deviceName:String, locationName: String, lat: Double, lng: Double) {
        self.id = UUID().uuidString
        self.deviceName = deviceName
        self.locationName = locationName
        self.visits = []
        self.visits.append(VisitRecord(deviceName: Persistance.shared.getDeviceName(), lat: lat, lng: lng))
        self.datetime = Date().timeIntervalSince1970
        self.spare = ""
    }

    required init(from decoder:Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        deviceName = try values.decode(String.self, forKey: .deviceName)
        locationName = try values.decode(String.self, forKey: .locationName)
        datetime = try values.decode(TimeInterval.self, forKey: .datetime)
        spare = try values.decode(String.self, forKey: .spare)
        visits = try values.decode([VisitRecord].self, forKey: .visits)
    }
        
    static func < (lhs: LocationRecord, rhs: LocationRecord) -> Bool {
        if lhs.locationName < rhs.locationName {
            return true
        }
        else {
            return lhs.datetime < rhs.datetime
        }
    }
    
    static func == (lhs: LocationRecord, rhs: LocationRecord) -> Bool {
        return lhs.locationName == rhs.locationName && lhs.datetime == rhs.datetime
    }
    
    func addRevisit(rec:VisitRecord) {
        self.visits.append(rec)
    }
}

class LocationStatus : ObservableObject {
    var lastStableLocation:CLLocationCoordinate2D?
    var message:String?
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published public var locations : [LocationRecord] = []
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentHeading: CLLocationDirection?
    @Published public var status: LocationStatus = LocationStatus()
    @Published public var lastStableLocation: CLLocationCoordinate2D?

    static public let shared = LocationManager()
    private let locationManager = CLLocationManager()
    private var locationReadCount = 0
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
        locations = []
        if let data = UserDefaults.standard.data(forKey: "GPSData") {
            if let decoded = try? JSONDecoder().decode([LocationRecord].self, from: data) {
                locations = decoded
                for loc in self.locations {
                    print(" revisit", loc.locationName, loc.visits.count)
                }
            }
            else {
                setStatus("ERROR:Cant load locations")
            }
        }
        
        setStatus("Loaded locations, length \(self.locations.count)")
        print("===>locaed locations 1", self.locations.count)
        //loadFromCloud()
    }
    
    private func setStatus(_ msg: String) {
        DispatchQueue.main.async {
            self.status.message = msg
            if let loc = self.currentLocation {
                self.status.message! += "\nCurrent:" + String(String(format: "%.4f",loc.latitude) + ", "  + String(String(format: "%.4f",loc.longitude)))
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
            if lastStableLocCounter >= 0 { // 5 todo
                lastStableLocation = currentLocation
            }
            else {
                self.lastStableLocation = nil
            }
        }
        DispatchQueue.main.async { [self] in
            self.setStatus("Count:\(self.locationReadCount) Delta:" + (deltaStr) + " Consec:" + String(lastStableLocCounter))
        }
    }
    
    public func resetLastStableLocation() {
        DispatchQueue.main.async {
            self.lastStableLocation = nil
            self.lastStableLocCounter = 0
        }
    }
    
    func saveLocation(rec: LocationRecord) {
        DispatchQueue.main.async {
            self.locations.append(rec)
            Persistance.shared.saveLocations(locations: self.locations)
            self.setStatus("saved length \(self.locations.count)")
            print("saved locs", self.locations.count)
        }
        self.currentLocation = nil
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

    func clearList() {
        self.locations.removeAll()
        UserDefaults.standard.removeObject(forKey: "GPSData")
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
    
    func fmtDatetime(datetime : TimeInterval) -> String {
        let dt  = Date(timeIntervalSince1970:datetime)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MMM-dd HH:mm"
        let dateString = formatter.string(from: dt)
        return dateString
    }
}

