import Foundation
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth
import FirebaseStorage
import AVFoundation

class LocationCloudPersistence : NSObject, ObservableObject {
    static public let shared = LocationCloudPersistence()
    @Published public var deviceName:String?
    
    private let collection = Firestore.firestore().collection("locations")
    
    override init() {
        super.init()
        if let dev = UserDefaults.standard.string(forKey: "GPSDeviceName") {
            self.deviceName = dev
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
            var pictureLocations:[LocationRecord] = []
            var locationCnt = 0
            var visitCnt = 0
            if let err = err {
                MessageHandler.shared.reportError(context: "Get Locations", err.localizedDescription)
            } else {
                for document in querySnapshot!.documents {
                    if let locationName = document.get("locationName") {
                        let visits = document.get("visits") as! NSDictionary
                        var location:LocationRecord?
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
                            let pictureURL = document.get("pictureURL")
                            if let url = pictureURL {
                                location.pictureURL = url as? String
                                pictureLocations.append(location)
                            }
                        }
                        locationCnt += 1
                    }
                    MessageHandler.shared.setStatus("Loaded \(locationCnt) locations, \(visitCnt) visits")
                }
            }
            
            // load pictures
            //https://firebase.google.com/docs/storage/ios/download-files
            
            DispatchQueue.main.async {
                for location in pictureLocations {
                    if let url = location.pictureURL {
                        let storage = Storage.storage()
                        let httpsReference = storage.reference(forURL: url)
                        httpsReference.getData(maxSize: 32 * 1024 * 1024) { data, error in
                            if let error = error {
                                MessageHandler.shared.reportError(context: "Load pictures", error.localizedDescription)
                            } else {
                                if let data = data {
                                    location.pictureSet.pictures.append(data)
                                }
                            }
                        }
                    }
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
            "pictureURL" : location.pictureURL as Any
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
        MessageHandler.shared.setStatus("Saved \(location.locationName)")
    }
    
    func savePictures(location:LocationRecord, ref:DocumentReference) {
        //https://firebase.google.com/docs/storage/ios/create-reference
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("images/\(location.getID() + "_" + location.locationName).jpg")

        let uploadTask = imageRef.putData(location.pictureSet.pictures[0], metadata: nil) { (metadata, error) in
//            guard let metadata = metadata else {
//                MessageHandler.shared.reportError(context: "Save Picture", "No metadata")
//                return
//            }
            imageRef.downloadURL { (url, error) in
                guard let url = url else {
                    MessageHandler.shared.reportError(context: "Storage save, no URL", "")
                    return
                }
                let downloadUrl = "\(url)"
                ref.updateData([
                    "pictureURL" : downloadUrl
                    ])
                MessageHandler.shared.setStatus("Save picture updated:\(location.locationName)")
            }
        }
    }
    
    func deleteLocation(locationId:String) {
        let doc = collection.document(locationId)
        doc.delete()
        MessageHandler.shared.setStatus("Deleted \(locationId)")
    }
}
