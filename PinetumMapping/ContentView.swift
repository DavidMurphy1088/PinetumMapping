import SwiftUI
import CoreData
import SwiftUI
import CoreLocation
import CoreLocationUI
import CoreLocation
import UIKit
import FirebaseAnalyticsSwift

struct ContentView: View {
    var body: some View {
        TabView {
            GPSReadView()
                .tabItem {
                    Label("GPSRead", image: "compassIcon")
                }

            LocationsView()
                .tabItem {
                    Label("Distances", image: "listIcon")
                    //Image("listIcon").frame(width: 5, height: 5)
                }
        }
        .navigationTitle("GPS Reader")
        .analyticsScreen(name: "ContentTest")
    }
}

struct GPSReadView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var persistence = Persistance.shared
    
    @State private var savePopup = false
    @State private var savePopup1 = false
    @State private var locationName: String = ""
    @State private var addDirections = false
    @State var fsTest = Persistance()
    @State var showingDeviceNamePopover = false
    @State var deviceName: String = ""

    func fmt(_ l: CLLocationCoordinate2D) -> String {
        return String(format: "%.5f", l.latitude)+",  "+String(format: "%.5f", l.longitude)
    }
    
    func saveForm(cords:CLLocationCoordinate2D?) -> some View {
        Form {
            VStack {
                VStack(alignment: .center) {
                    Text("Save Location").font(.title2).bold()
                    if let message = locationManager.status.message {
                        Text(message).foregroundColor(.gray)
                    }
                    TextField("name of location", text: $locationName)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .padding()
//                    Toggle("Add Directions?", isOn: $addDirections)
//                        .padding()
                }
                
                HStack {
                    Spacer()
                    Button("Cancel") {
                        savePopup = false
                    }
                    Spacer()
                    Button("Save") {
                        if let saveCords = cords {
                            let rec = LocationRecord(
                                deviceName: Persistance.shared.getDeviceName(),
                                locationName: locationName,
                                lat: saveCords.latitude, lng: saveCords.longitude)
                            self.locationManager.saveLocation(rec: rec)
                            //                        if false && addDirections {
                            //                            let delta = 0.0002
                            //                            rec = LocationRecord(name: locationName+"_NE",
                            //                                                 lat: l.latitude + delta,
                            //                                                 lng: l.longitude + delta)
                            //                            self.locationManager.saveLocation(rec: rec)
                            //                            rec = LocationRecord(name: locationName+"_NW",
                            //                                                 lat: l.latitude + delta,
                            //                                                 lng: l.longitude - delta)
                            //                            self.locationManager.saveLocation(rec: rec)
                            //                            rec = LocationRecord(name: locationName+"_SE",
                            //                                                 lat: l.latitude - delta,
                            //                                                 lng: l.longitude + delta)
                            //                            self.locationManager.saveLocation(rec: rec)
                            //                            rec = LocationRecord(name: locationName+"_SW",
                            //                                                 lat: l.latitude - delta,
                            //                                                 lng: l.longitude - delta)
                            //                            self.locationManager.saveLocation(rec: rec)
                            //                        }
                            locationManager.resetLastStableLocation()
                        }
                        savePopup = false
                    }
                    .disabled(cords == nil)
                    .disabled(locationName.count == 0)
                    Spacer()
                }
            }
        }
    }
    
    func saveLocation() -> some View {
        VStack {
            VStack(alignment: .leading) {
                Button("Save Location") {
                    savePopup.toggle()
                }
            }
            .popover(isPresented: $savePopup) {
                saveForm(cords: locationManager.lastStableLocation!)
            }
        }
    }
    
    func gpsView() -> some View {
        VStack {
            Text("GPS Reader").font(.title2).bold()
            Spacer()
            Text("Device Name: " + (self.persistence.getDeviceName()))
            if let message = locationManager.status.message {
                Spacer()
                Text(message)
            }
            if let message = persistence.status {
                Spacer()
                Text(message)
            }
            if locationManager.currentLocation == nil {
                Spacer()
                Text("Start Location Manager")
                .foregroundColor(.green)
                .font(.title3)
                LocationButton {
                    locationManager.requestLocation()
                }
                .symbolVariant(.fill)
                .labelStyle(.titleAndIcon)
            }
            
            VStack {
                Spacer()
//                Button("Test Filestore") {
//                    let loc = LocationRecord
//                    fsTest.test(location: locationRecord)
//                }
                Spacer()
                Button("Save Location") {
                    savePopup.toggle()
                }
                .disabled(locationManager.lastStableLocation == nil)
                .popover(isPresented: $savePopup) {
                    saveForm(cords: locationManager.lastStableLocation)
                }
                //saveLocation().disabled(locationManager.lastStableLocation == nil)
                
                Spacer()
                Button("Reset Location Manager") {
                    locationManager.reset()
                }
                Spacer()
            }
        }

    }
    
    var body: some View {
        VStack {
            if persistence.deviceName != nil {
                self.gpsView()
            }
            else {
                Spacer()
                Button("Set Device Name") {
                    showingDeviceNamePopover = true
                }
                .padding()
                .popover(isPresented: $showingDeviceNamePopover) {
                    Text("Pleaes enter your device name")
                    TextField("device name/user name", text: $deviceName)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .frame(width: 300)
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            showingDeviceNamePopover = false
                        }
                        Spacer()
                        Button("Save") {
                            self.persistence.saveDeviceName(name: deviceName)
                            showingDeviceNamePopover = false
                        }
                        Spacer()
                    }
                }
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
