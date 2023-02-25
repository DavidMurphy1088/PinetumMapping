import SwiftUI
import CoreData
import SwiftUI
import CoreLocation
import CoreLocationUI
import CoreLocation
import UIKit
import FirebaseAnalyticsSwift

struct ContentView: View {
    @ObservedObject var errors = ErrorHandler.shared
    @State private var showingAlert = false

    var body: some View {
        TabView {
            MappingView()
                .tabItem {
                    Label("GPSRead", image: "compassIcon")
                }

            LocationsView()
                .tabItem {
                    Label("Distances", image: "listIcon")
                }
        }
        //.navigationTitle("GPS Reader")
        //.analyticsScreen(name: "ContentTest")
        //TODO and add to error cases
        .alert..("Important message", isPresented: $errors.showingAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

struct MappingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var locations = LocationRecords.shared
    @ObservedObject var persistence = LocationCloudPersistence.shared
    
    @State private var saveLocationPopup = false

    @State var showingDeviceNamePopover = false
    @State var deviceName: String = ""
    @State private var stability: Double = 0 //todo
    
//    func fmt(_ l: CLLocationCoordinate2D) -> String {
//        return String(format: "%.5f", l.latitude)+",  "+String(format: "%.5f", l.longitude)
//    }

    func GPSView() -> some View {
        NavigationView {
            VStack {
                Text("GPS Reader").font(.title2).bold()
                if let message = locationManager.status {
                    Spacer()
                    Text(message)//.font(.)
                }
                if let message = persistence.status {
                    Spacer()
                    Text("Persist Mgr: " + message).font(.caption)
                }
                if let err = ErrorHandler.shared.error {
                    Spacer()
                    Text("Error: " + err).font(.caption)
                }
 
                if locationManager.currentLocation == nil {
                    Spacer()
                    Text("Start Location Manager") //TODO
                        .foregroundColor(.red)
                        .font(.title3)
                        .padding()
                    LocationButton {
                        locationManager.requestLocation()
                    }
                    .symbolVariant(.fill)
                    .labelStyle(.titleAndIcon)
                    .padding()
                }
                
                VStack {
                    Spacer()
                    LocationPointsPlotView(count: locationManager.stableLocationsCount)
                    Spacer()
                    HStack {
                        Spacer()
                        if let bestLocation = locationManager.getBestLocation() {
                            NavigationLink("Save Location") {
                                SaveLocationView(location: bestLocation)
                            }
                        }
                        Spacer()
                        Button("Reset GPS") {
                            locationManager.reset()
                        }
                        Spacer()
                    }
                    
                    VStack {
                        Slider(value: $stability, in: 0...6)
                            .onChange(of: stability) { newValue in
                                locationManager.requiredStabilityCounter = Int(stability)
                            }
                        Text("Required stability is \(stability, specifier: "%.0f")")
                    }
                    .padding()
                    Spacer()
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            if persistence.deviceName != nil {
                self.GPSView()
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

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
