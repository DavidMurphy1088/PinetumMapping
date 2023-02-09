import Foundation
import FirebaseFirestore
import FirebaseCore

class Persistance : NSObject, ObservableObject {
    static public let shared = Persistance()
    @Published public var status = ""
    @Published public var deviceName:String?
    
    override init() {
        super.init()
        if let dev = UserDefaults.standard.string(forKey: "GPSDeviceName") {
            self.deviceName = dev
        }
    }
    
    private func setStatus(_ msg: String) {
        DispatchQueue.main.async {
            self.status = msg
        }
    }
    
    public func saveDeviceName(name:String) {
        UserDefaults.standard.set(name, forKey: "GPSDeviceName")
        DispatchQueue.main.async {
            self.deviceName = name
        }
    }
    
    func getDeviceName() -> String {
        if let name = self.deviceName {
            return name
        }
        else {
            return "unknown"
        }
    }
    
    func saveLocations(locations:[LocationRecord]) {
        //https://console.firebase.google.com/project/pinetummapping/firestore/data/~2Fdavid~2FUDi413pCCgtuVlhqz69U
        //data at https://console.firebase.google.com/project/pinetummapping/firestore/data/~2Flocations~2FjshsDAQ6l48ATgsdBtGT
        //device check for authorized, App not registered https://stackoverflow.com/questions/70809709/how-do-i-overcome-appcheck-failed-on-ios-15-2-firebase-v8-11-0
        let db = Firestore.firestore()
        
        //https://firebase.google.com/docs/firestore/manage-data/add-data
        
        for location in locations {
            let docId = "\(location.id)"
            db.collection("locations").document(docId).setData([
                "deviceName" : location.deviceName,
                "locationName" : location.locationName,
                "datetime" : location.datetime
            ])
            let ref = db.collection("locations").document(docId)
            var n = 0
            for visit in location.visits {
                ref.updateData([
                    "visits.\(n)": [ "device" : visit.deviceName,
                                     "datetime" : visit.datetime,
                                     "lng": visit.longitude, "lat": visit.latitude]
                ])
                n += 1
//                ref.updateData([
//                    "visits.\(n)": [ "lng": visit.longitude, "lat": visit.latitude]
//                ])
//                ref.updateData([
//                    "visits.2": [ "food": "Pizza222", "color22": "Blue", "subject":
//                ])
            }

            // Atomically add a new region to the "regions" array field.
//            ref.updateData([
//                "visits": FieldValue.arrayUnion(["v1"])
//            ])
//            let ref1 = db.collection("locations").document(docId).
//            for visit in location.visits {
//                ref.updateData([
//                    "visits.1": FieldValue.arrayUnion(
//                        [visit.longitude,
//                         visit.datetime]
//                    )
//                ])
//            }
            break
        }
    }
}
