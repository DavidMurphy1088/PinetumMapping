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
    @ObservedObject private var status = LocationManager.shared.status
    @State private var isPresentingConfirm = false
    @State private var isPresentingDeleteLocation = false

    func delete(at offsets: IndexSet) {
        locationManager.locations.remove(atOffsets: offsets)
    }
    
    func locationDisplayLine(rec:LocationRecord) -> String {
        let now = Date(timeIntervalSince1970:rec.datetime)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MMM-dd HH:mm"
        let dateString = formatter.string(from: now)
        var ret = rec.locationName + "\t" + dateString
        if let loc = locationManager.currentLocation {
            ret += "\nDist to current:" + String(format: "%.1f",
                                     locationManager.distance(startLat:rec.visits[0].latitude, startLng:rec.visits[0].longitude,
                                                              endLat: loc.latitude,
                                                              endLng: loc.longitude))
        }
        else {
            ret += " dist:Unknown"
        }
        ret += "\nVisits cnt:" + String(rec.visits.count)
        return ret
    }
    
    
    var body: some View {
        VStack {
            NavigationStack {
                Text("Saved Locations").font(.title2).bold().padding()
                if let message = locationManager.status.message {
                    Text(message).foregroundColor(.gray)
                }
                
                List {
                    Text("Swipe row left to delete").font(.caption)//.foregroundColor(.gray)
                    ForEach(locationManager.locations.sorted(), id: \.datetime) { location in
                        NavigationLink(value: location, label: {
                        Text(locationDisplayLine(rec: location)).font(.system(size: 18))
                                .font(.subheadline.weight(.medium))
                        })
                    }
                    .onDelete(perform: delete)
                    //.confirmationDialog("Are you sure?",
                }
                .navigationDestination(for: LocationRecord.self, destination: { loc in
                    LocationView(locationRecord: loc)
                            })
                //.navigationTitle(Text("Locations")) //.font(.title2).bold())
                Button("Clear List", role: .destructive) {
                      isPresentingConfirm = true
                }
               .confirmationDialog("Are you sure?",
                    isPresented: $isPresentingConfirm) {
                    Button("Delete all locations?", role: .destructive) {
                        locationManager.clearList()
                    }
                }
            }

//            .onChange(of: scenePhase) { phase in
//                if phase != .active {
//                    locationManager.persistLocations()
//                }
//            }
        }
    }
}
