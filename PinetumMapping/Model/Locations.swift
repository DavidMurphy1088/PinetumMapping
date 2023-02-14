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
    var id:String
    public var visits : [VisitRecord] = []
    var locationName:String
    var spare:String
    var deleted = false
    
    init(id:String? = nil, locationName: String, lat: Double, lng: Double) {
        if let id = id {
            self.id = id
        }
        else {
            self.id = UUID().uuidString
        }
        self.locationName = locationName
        self.visits = []
        self.spare = ""
        self.visits.append(VisitRecord(deviceName: GPSPersistence.shared.getDeviceName(), lat: lat, lng: lng))
    }

//    required init(from decoder:Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        id = try values.decode(String.self, forKey: .id)
//        locationName = try values.decode(String.self, forKey: .locationName)
//        spare = try values.decode(String.self, forKey: .spare)
//        visits = try values.decode([VisitRecord].self, forKey: .visits)
//    }
        
    static func < (lhs: LocationRecord, rhs: LocationRecord) -> Bool {
        if lhs.locationName < rhs.locationName {
            return true
        }
        else {
            return lhs.visits[0].datetime < rhs.visits[0].datetime
        }
    }
    
    static func == (lhs: LocationRecord, rhs: LocationRecord) -> Bool {
        return lhs.locationName == rhs.locationName && lhs.visits[0].datetime == rhs.visits[0].datetime
    }
    
}

class Locations: NSObject, ObservableObject {
    static public let shared = Locations()
    
    @Published private var locations : [LocationRecord] = []
    @Published var status: String?
    
    override init() {
        locations = []
//            if let data = UserDefaults.standard.data(forKey: "GPSData") {
//                if let decoded = try? JSONDecoder().decode([LocationRecord].self, from: data) {
//                    locations = decoded
//                    for loc in self.locations {
//                        print(" revisit", loc.locationName, loc.visits.count)
//                    }
//                }
//                else {
//                    setStatus("ERROR:Cant load locations")
//                }
//            }
        GPSPersistence.shared.getLocations()
    }
    
    public func getLocations() -> [LocationRecord] {
        return locations
    }
    
    private func setStatus(_ msg: String) {
        DispatchQueue.main.async {
            self.status = msg
        }
    }
    
    func clearList() {
        //self.locations.removeAll()
        //UserDefaults.standard.removeObject(forKey: "GPSData")
        //TOOD Firebase delete
    }
    
    func addLocation(location: LocationRecord) {
        DispatchQueue.main.async {
            self.locations.append(location)
            GPSPersistence.shared.saveLocation(location: location)
            self.setStatus("Saved \(location.locationName)")
        }
    }

    func addVisit(location:LocationRecord, visit:VisitRecord) {
        DispatchQueue.main.async {
            location.visits.append(visit)
            GPSPersistence.shared.saveLocation(location: location)
        }
    }
    
    func deleteVisit(location:LocationRecord, visitNum:Int) {
        DispatchQueue.main.async {
            location.visits.remove(at: visitNum)
            GPSPersistence.shared.saveLocation(location: location)
        }
    }
    
    func deleteLocation(row: Int) {
        DispatchQueue.main.async {
            let delLoc = self.locations[row]
            let name = delLoc.locationName
            self.locations.remove(at: row)
            GPSPersistence.shared.deleteLocation(locationId: delLoc.id)
            self.setStatus("Deleted \(name)")
        }
    }

}
