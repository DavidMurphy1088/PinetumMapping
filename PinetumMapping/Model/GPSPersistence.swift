import Foundation
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth
import FirebaseStorage

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
                        //let id = document.documentID
                        for (key, _) in visits {
                            let visitNum = visits[key] as! NSDictionary
                            let datetime = visitNum["datetime"] as! Double
                            let lat = visitNum["lat"] as! Double
                            let lng = visitNum["lng"] as! Double
                            let pictureSet = PictureSet(pictures: [])
                            if let location = location {
                                let visit = LocationVisitRecord(deviceName: visitNum["device"] as! String, datetime: datetime, lat: lat, lng: lng)
                                location.visits.append(visit)
                            }
                            else {
                                location = LocationRecord(id:document.documentID, locationName: locationName as! String, datetime: datetime, lat: lat, lng: lng, pictureSet: pictureSet)
                            }
                            visitCnt += 1
                        }
                        
                        if let location = location {
                            LocationRecords.shared.addLocation(location: location)
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
            "locationName" : location.locationName,
        ])
        let ref = collection.document(docId)
        var i = 0
        for picture in location.pictureSet.pictures {
            ref.updateData([
                "pictureData" : "Picture:\(i), size:\(picture.count)",
            ])
            i += 1
        }
        var n = 0
        for visit in location.visits {
            ref.updateData([
                "visits.\(n)": [ "device" : visit.deviceName,
                                 "datetime" : visit.datetime,
                                 "lng": visit.longitude, "lat": visit.latitude]
            ])
            n += 1
        }
        
        if location.pictureSet.pictures.count > 0 {
            DispatchQueue.global(qos: .background).async {
                self.savePictures(location: location, ref: ref)
            }
        }
        self.setStatus("Saved \(location.locationName)")
    }
    
    func savePictures(location:LocationRecord, ref:DocumentReference) {
        //https://firebase.google.com/docs/storage/ios/create-reference
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let riversRef = storageRef.child("images/\(location.locationName).jpg")

        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = riversRef.putData(location.pictureSet.pictures[0], metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                self.status = "Storage save, metadata, \(error?.localizedDescription ?? "?")"
                //print("============= Uh-oh, an error occurred!", error?.localizedDescription)
                return
            }
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            // You can also access to download URL after upload.
            riversRef.downloadURL { (url, error) in
                guard let url = url else {
                    self.status = "Storage save, download URL, \(error?.localizedDescription ?? "?")"
                    //print("=========== Uh-oh, an error occurred! ......", error?.localizedDescription)
                    return
                }
                let downloadUrl = "\(url)"
                ref.updateData([
                    "pictureURL" : downloadUrl
                    ])
                    self.status = "Storage, updated:\(location.locationName) URL:\(downloadUrl)"
            }
        }
    }
    
    func deleteLocation(locationId:String) {
        let doc = collection.document(locationId)
        print("========delete", "id:", locationId)
        doc.delete()
        self.setStatus("Deleted \(locationId)")
    }
}
