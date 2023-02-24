import Foundation
import CoreLocation
import MapKit

class LocationVisitRecord : Codable, Hashable {
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
    
    static func == (lhs: LocationVisitRecord, rhs: LocationVisitRecord) -> Bool {
        return lhs.datetime < rhs.datetime
    }
    
    static func < (lhs: LocationVisitRecord, rhs: LocationVisitRecord) -> Bool {
        return lhs.datetime < rhs.datetime
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(String(self.datetime))
    }
}

class PictureSet {
    var pictures:[Data] = []
    init (pictures:[Data] ) {
        self.pictures = pictures
    }
}

class LocationRecord : NSObject, Comparable, ObservableObject, Identifiable { //
    internal var id:String
    public var visits : [LocationVisitRecord] = []
    var locationName:String
    var spare:String
    var pictureSet:PictureSet
    
    init(id:String, locationName: String, datetime:TimeInterval, lat: Double, lng: Double, pictureSet:PictureSet) {
        self.id = id
        self.locationName = locationName
        self.visits = []
        self.spare = ""
        self.pictureSet = pictureSet
        self.visits.append(LocationVisitRecord(deviceName: GPSPersistence.shared.getDeviceName(), datetime: datetime, lat: lat, lng: lng))
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
        return lhs.id == rhs.id
    }
    
}

class LocationRecords: NSObject, ObservableObject {
    static public let shared = LocationRecords()
    
    @Published var locations : [LocationRecord] = []
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

    func addVisit(location:LocationRecord, visit:LocationVisitRecord) {
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
    
    func deleteLocation(deleteLocation:LocationRecord) {
        DispatchQueue.main.async {
            //if indexSet.count == 1 {
                //if let row = indexSet.min() {
                    //let delLoc = self.locations[row]
                    //let name = delLoc.locationName
                    //print("deleteLocation", row, delLoc.locationName, delLoc.getID())
            var i = 0
            for loc in self.locations{
                if loc.getID() == deleteLocation.getID() {
                    self.locations.remove(at: i)
                    GPSPersistence.shared.deleteLocation(locationId: deleteLocation.getID())
                    self.setStatus("Deleted \(deleteLocation.locationName)")
                    break
                }
                i+=1
            }
        }
    }

}

