import Foundation
import SwiftUI
import CoreData
import CoreLocation
import CoreLocationUI
import CoreLocation
import UIKit
import MapKit

struct LocationsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var locations = LocationRecords.shared
    @ObservedObject var persistence = LocationCloudPersistence.shared
    @State private var isPresentingConfirm = false
    @State private var isPresentingDeleteLocation = false
        
    func delete(at offsets: IndexSet) {
        let sorted = locations.getLocations().sorted()
        let delLoc = sorted[offsets.min()!]
        
        var i = 0
        for loc in locations.getLocations() {
            if loc.getID() == delLoc.getID() {
                locations.locations.remove(at: i)
                persistence.deleteLocation(locationId: delLoc.getID())
                break
            }
            i+=1
        }
    }
    
    func locationDisplayLine(rec:LocationRecord) -> String {
        let now = Date(timeIntervalSince1970:rec.visits[0].datetime)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MMM-dd HH:mm"
        let dateString = formatter.string(from: now)
        var ret = rec.locationName + "\t" + dateString + "\t" + rec.visits[0].deviceName
        if let meanLoc = locationManager.getMeanLocation() {
            ret += "\nDist to current:" + String(format: "%.1f",
                                     locationManager.distance(startLat:rec.visits[0].latitude, startLng:rec.visits[0].longitude,
                                                              endLat: meanLoc.latitude,
                                                              endLng: meanLoc.longitude))
        }
        else {
            ret += " dist:Unknown"
        }
        ret += "\nVisits:" + String(rec.visits.count)
        return ret
    }
    
    var body: some View {
        VStack {
            NavigationStack {
                Text("Saved Locations").font(.title2).bold().padding()
//                if let message = locationManager.status {
//                    Text(message)
//                }
//                if let message = persistence.status {
//                    Spacer()
//                    Text(message)
//                }
                List {
                    Text("Swipe row left to delete").font(.caption)
                    ForEach(locations.getLocations().sorted()) { location in
                        NavigationLink(value: location, label: {
                            Text(locationDisplayLine(rec: location)).font(.system(size: 18))
                                    .font(.subheadline.weight(.medium))
                        })
                    }
                    .onDelete(perform: delete)
                }
                .navigationDestination(for: LocationRecord.self, destination: { loc in
                    LocationVisitsView(locations: locations, location: loc)
                })
                Button("Clear List", role: .destructive) {
                      isPresentingConfirm = true
                }
               .confirmationDialog("Are you sure?",
                    isPresented: $isPresentingConfirm) {
                    Button("Delete all locations?", role: .destructive) {
                        //locationManager.clearList()
                    }
                }
            }
        }
    }
}
