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
    
    init(deviceName:String, datetime:TimeInterval, lat:Double, lng:Double) {
        self.deviceName = deviceName
        self.datetime = datetime
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
    private var id:String
    public var visits : [VisitRecord] = []
    var locationName:String
    var spare:String
    
    init(id:String, locationName: String, datetime:TimeInterval, lat: Double, lng: Double) {
        self.id = id
        self.locationName = locationName
        self.visits = []
        self.spare = ""
        self.visits.append(VisitRecord(deviceName: GPSPersistence.shared.getDeviceName(), datetime: datetime, lat: lat, lng: lng))
    }
        
    func getID() -> String {
        return self.id
    }
    
    static func < (lhs: LocationRecord, rhs: LocationRecord) -> Bool {
        if lhs.locationName < rhs.locationName {
            return true
        }
        else {
            return lhs.visits[0].datetime < rhs.visits[0].datetime
        }
    }
    
    static func == (lhs: LocationRecord, rhs: LocationRecord) -> Bool {
        //return lhs.locationName == rhs.locationName && lhs.visits[0].datetime == rhs.visits[0].datetime
        return lhs.id == rhs.id
    }
    
}

class Locations: NSObject, ObservableObject {
    static public let shared = Locations()
    
    @Published private var locations : [LocationRecord] = []
    @Published var status: String?
    
    override init() {
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
    
    func deleteLocation(indexSet: IndexSet) {
        DispatchQueue.main.async {
            if indexSet.count == 1 {
                if let row = indexSet.min() {
                    let delLoc = self.locations[row]
                    let name = delLoc.locationName
                    self.locations.remove(at: row)
                    print("========......start", indexSet.startIndex, "end", indexSet.endIndex, "count", indexSet.count, indexSet.min(), indexSet.max())
                    GPSPersistence.shared.deleteLocation(locationId: delLoc.getID())
                    self.setStatus("Deleted \(name)")
                }
            }
        }
    }

}

