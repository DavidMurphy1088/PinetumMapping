import Foundation
import SwiftUI
import CoreData
import CoreLocation
import CoreLocationUI
import CoreLocation
import UIKit

struct LocationVisitsView: View {
    @ObservedObject var locations:LocationRecords
    @ObservedObject var location:LocationRecord
    @ObservedObject var locationManager = LocationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var angle = 0.0
    @State private var savePopup = false
    
    func saveForm(saveLocation:CLLocationCoordinate2D) -> some View {
        Form {
            VStack {
                VStack(alignment: .center) {
                    Text("Save a New Location Revisit").font(.title2).bold()
                    if let message = locationManager.status {
                        Text("\n"+message+"\n")
                    }
                }
                HStack {
                    Spacer()
                    Button("Cancel") {
                        savePopup = false
                    }
                    Spacer()
                    Button("Save") {
                        let revisitRecord = LocationVisitRecord(deviceName: GPSPersistence.shared.getDeviceName(), datetime: NSDate().timeIntervalSince1970, lat: saveLocation.latitude, lng: saveLocation.longitude)
                        locations.addVisit(location: location, visit: revisitRecord)
                        //locationManager.resetLastStableLocation()
                        savePopup = false
                    }
                    .disabled(locationManager.getBestLocation() == nil)
                    Spacer()
                }
            }
        }
    }
    
    func saveVisitView(saveLocation:CLLocationCoordinate2D?) -> some View {
        VStack {
            VStack(alignment: .leading) {
                Button("Save Location Visit") {
                    savePopup.toggle()
                }
                .padding()
                .disabled(saveLocation == nil)
            }.popover(isPresented: $savePopup) {
                if let loc = saveLocation {
                    saveForm(saveLocation: loc)
                }
            }
        }
    }

    func visitLine(rec : LocationVisitRecord) -> String {
        var ret = Util.fmtDatetime(datetime: rec.datetime) + "\t" + rec.deviceName
        let firstVisit = location.visits[0]
        if let bestLoc = locationManager.getBestLocation() {
            let currDist = locationManager.distance(startLat: bestLoc.latitude, startLng: bestLoc.longitude, endLat: rec.latitude, endLng: rec.longitude)
            ret += "\nDistance to current:"+String(format: "%.1f",currDist)
        }
        let firstDist = locationManager.distance(startLat: firstVisit.latitude, startLng: firstVisit.longitude, endLat: rec.latitude, endLng: rec.longitude)
        ret += "\nDistance to first:"+String(format: "%.1f",firstDist)
        return ret
    }
    
    func delete(at offsets: IndexSet) {
        let min = offsets.min()
        if let index = min {
            if index > 0 {
                //must return he zero entry for the location's GPS locations
                locations.deleteVisit(location: location, visitNum: index)
            }
        }
    }

    var body: some View {
        VStack {
            Text("Location:" + location.locationName).font(.title2).bold()
            Text("Distance from current location:" + String(format: "%.1f",distance()))
            if let message = locationManager.status {
                Text(message).font(.caption)
            }

            Image("pointer")
            .resizable()
            .rotationEffect(.degrees(bearing()))
            .animation(.easeIn, value: bearing())

            List {
                Text("Visits to this location").font(.title3).bold()
                ForEach(location.visits, id: \.datetime) { revisit in
                    Text(self.visitLine(rec: revisit))
                }
                //.onDelete(perform: revisit.de ? delete : nil)
                .onDelete(perform: delete)
            }
            saveVisitView(saveLocation: locationManager.getBestLocation())
        }
    }
    
    func DegreesToRadians(_ degrees: Double ) -> Double {
        return degrees * Double.pi / 180
    }

    func RadiansToDegrees(_ radians: Double) -> Double {
        return radians * 180 / Double.pi
    }

    func bearingToLocationRadian1(srcLat:Double, srcLong:Double) -> Double {
        //house             -41.27835695935406, 174.76827635559158
        //well              -41.2924  174.7787
        //well east coast   -41.2634, 175.8878
        //far east          -41.3915, 178.2385
        
        //west coast        -41.2773, 174.6222
        //south west        -42.1333, 172.7399
        //far west          -41.1189, 170.1745
        
        let lat1 = srcLat
        let lon1 = srcLong
        
        let lat2 = location.visits[0].latitude
        let lon2 = location.visits[0].longitude

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x)

        return radiansBearing
    }

    func bearingToLocationDegrees(currentLat:Double, currentLong:Double) -> Double {
        //θ = atan2( sin Δλ ⋅ cos φ2 , cos φ1 ⋅ sin φ2 − sin φ1 ⋅ cos φ2 ⋅ cos Δλ )
        //where    φ1,λ1 is the start point, φ2,λ2 the end point (Δλ is the difference in longitude)
        //1 = current, 2 = location record

        let y = sin(location.visits[0].longitude-currentLong) * cos(location.visits[0].latitude);
        let x = cos(currentLat)*sin(location.visits[0].latitude) -
        sin(currentLat)*cos(location.visits[0].latitude)*cos(location.visits[0].longitude-currentLong);
        let radians = atan2(y, x);
        //let brng = (theta*180/Double.pi + 360) % 360; // in degrees
        let brng = radians * 180 / Double.pi
        return 0 - brng
    }
        
    func bearing() -> Double {
        var res:Double = 0
        if let loc = locationManager.currentLocation {
            res =  bearingToLocationDegrees(currentLat: loc.latitude, currentLong: loc.longitude)
            res += angle
        }
        else {
            res = 0
        }
        return res
    }
    
    func distance() -> Double {
        if let cur = locationManager.getBestLocation() {
            return locationManager.distance(startLat:location.visits[0].latitude, startLng:location.visits[0].longitude,
                                            endLat: cur.latitude, endLng: cur.longitude)
        }
        else {
            return 0
        }
    }
    

}

