import Foundation
import FirebaseFirestore
import FirebaseCore

class GPSPersistence : NSObject, ObservableObject {
    static public let shared = GPSPersistence()
    @Published public var status = ""
    @Published public var deviceName:String?
    
    private let collection = Firestore.firestore().collection("locations")
    
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
    
    func getLocations() {
        let db = Firestore.firestore()
        db.collection("locations").getDocuments() { (querySnapshot, err) in
            var locationCnt = 0
            var visitCnt = 0
            if let err = err {
                self.setStatus("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    if let locationName = document.get("locationName") {
                        let visits = document.get("visits") as! NSDictionary
                        var location:LocationRecord?
                        let id = document.documentID
                        for (key, _) in visits {
                            let visitNum = visits[key] as! NSDictionary
                            let datetime = visitNum["datetime"] as! Double
                            let lat = visitNum["lat"] as! Double
                            let lng = visitNum["lng"] as! Double
                            if let location = location {
                                let visit = VisitRecord(deviceName: visitNum["device"] as! String, datetime: datetime, lat: lat, lng: lng)
                                location.visits.append(visit)
                            }
                            else {
                                location = LocationRecord(id:document.documentID, locationName: locationName as! String, datetime: datetime, lat: lat, lng: lng)
                            }
                            visitCnt += 1
                        }
                        
                        if let location = location {
                            Locations.shared.addLocation(location: location)
                        }
                        locationCnt += 1
                    }
                    self.setStatus("Loaded \(locationCnt) locations, \(visitCnt) visits")
                }
            }
        }
    }

    func saveLocation(location:LocationRecord) {
        let docId = "\(location.getID())"
        let doc = collection.document(docId)
        doc.delete()
        doc.setData([
            "locationName" : location.locationName
        ])
        let ref = collection.document(docId)
        var n = 0
        for visit in location.visits {
            ref.updateData([
                "visits.\(n)": [ "device" : visit.deviceName,
                                 "datetime" : visit.datetime,
                                 "lng": visit.longitude, "lat": visit.latitude]
            ])
            n += 1
        }
        self.setStatus("Saved \(location.locationName)")
    }
    
    func deleteLocation(locationId:String) {
        let doc = collection.document(locationId)
        doc.delete()
        self.setStatus("Deleted \(locationId)")
    }

//    func saveLocations(locations:[LocationRecord]) {
//        //https://console.firebase.google.com/project/pinetummapping/firestore/data/~2Fdavid~2FUDi413pCCgtuVlhqz69U
//        //data at https://console.firebase.google.com/project/pinetummapping/firestore/data/~2Flocations~2FjshsDAQ6l48ATgsdBtGT
//        //device check for authorized, App not registered https://stackoverflow.com/questions/70809709/how-do-i-overcome-appcheck-failed-on-ios-15-2-firebase-v8-11-0
//        //https://firebase.google.com/docs/firestore/manage-data/add-data
//        let db = Firestore.firestore()
//        var totVisits = 0
//
//        let docs = self.collection.getDocuments()  { (querySnapshot, err) in
//            for doc1 in querySnapshot!.documents {
//                print("====", doc1.get("locationName"), type(of: doc1))
//                //doc1.setValue("", forKey: "locationName")
//
//                //FIRQueryDocumentSnapshot
//            }
//        }
//        for location in locations {
//            let docId = "\(location.id)"
//            //print("================================= Saving id:", docId, location.visits.count)
//            let doc = collection.document(docId)
//            print("===>>", type(of: doc))
//
//            doc.delete()
//            doc.setData([
//                "locationName" : location.locationName
//            ])
//            let ref = db.collection("locations").document(docId)
//            var n = 0
//            for visit in location.visits {
//                ref.updateData([
//                    "visits.\(n)": [ "device" : visit.deviceName,
//                                     "datetime" : visit.datetime,
//                                     "lng": visit.longitude, "lat": visit.latitude]
//                ])
//                n += 1
//                totVisits += 1
//            }
//        }
//        self.setStatus("saved locations:\(locations.count) , visits:\(totVisits)")
//    }
}
