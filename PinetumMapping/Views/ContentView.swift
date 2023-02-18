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
                }
        }
        .navigationTitle("GPS Reader")
        .analyticsScreen(name: "ContentTest")
    }
}

struct GPSReadView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var locations = Locations.shared
    @ObservedObject var persistence = GPSPersistence.shared
    
    @State private var savePopup = false
    @State private var savePopup1 = false
    @State private var locationName: String = ""
    @State private var resetGPS = false
    @State var showingDeviceNamePopover = false
    @State var deviceName: String = ""
    @State private var stability: Double = 4
    
    func fmt(_ l: CLLocationCoordinate2D) -> String {
        return String(format: "%.5f", l.latitude)+",  "+String(format: "%.5f", l.longitude)
    }
    
    func saveForm(location:CLLocationCoordinate2D) -> some View {
        Form {
            VStack {
                VStack(alignment: .center) {
                    Text("Save Location").font(.title2).bold()
                    if let message = locationManager.status {
                        Text(message)//.foregroundColor(.gray)
                    }
                    TextField("name of location", text: $locationName)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .padding()
                    Toggle("Reset GPS?", isOn: $resetGPS)
                        .padding()
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Button("Cancel") {
                        savePopup = false
                    }
                    Spacer()
                    Button("Save") {
                        //if let location = location {
                            let rec = LocationRecord(
                                id: UUID().uuidString,
                                locationName: locationName,
                                datetime: Date().timeIntervalSince1970,
                                lat: location.latitude, lng: location.longitude)
                            self.locations.addLocation(location: rec)
                            if resetGPS {
                                locationManager.reset()
                            }
                        //}
                        savePopup = false
                    }
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
                saveForm(location: locationManager.bestLocation!)
            }
        }
    }
    
    // =============== 2D plot ==========================

    struct LocationPointsView: View {
        @State var count:Int
        @ObservedObject var count1 = LocationManager.shared
        @State var locationManager:LocationManager = LocationManager.shared
        private let diameter = 12.0
        
        func scale(dimension: Double) -> Double {
            if locationManager.stableLocationsCount <= 1 {
                return 0
            }
            var max = 0.0
            let center = locationManager.displayLocations[0]
            for location in locationManager.displayLocations {
                if abs(location.latitude - center.latitude) > max {
                    max = abs(location.latitude - center.latitude)
                }
                if abs(location.longitude - center.longitude) > max {
                    max = abs(location.longitude - center.longitude)
                }
            }
            var scale:Double
            if max == 0 {
                scale = 1.0
            }
            else {
                scale = Double(dimension/2.0) / max
            }
            scale = scale/1.2
            return scale
        }
        
        func x(_ location: StableLocation, width: Double) -> Double {
            let offset = width/2.0
            //let center = locationManager.stableLocations.locations[0]
            let res = (scale(dimension: width) * (location.latitude)) + offset
            return res
        }
        
        func y(_ location: StableLocation, height: Double) -> Double {
            let offset = height/2
            //let center = locationManager.stableLocations.locations[0]
            return scale(dimension: height) * (location.longitude) + offset
        }

        func color(_ plotType:Int) -> Color {
            switch plotType {
            case 0:
                return Color(.green)
            case 1:
                return Color(.blue)
            case 2:
                return Color(.cyan)
            case 3:
                return Color(.red)
            default:
                return Color(.black)
            }
        }
        
        var body: some View {
            GeometryReader { geometry in
                VStack {
                    ZStack {
                        //Rectangle().stroke(Color.gray, lineWidth: 3.0).frame(width: 300, height: 300, alignment: .center)
                        ForEach(0..<locationManager.displayLocations.count, id: \.self) { idx in
                            Circle()
                                .fill(color(locationManager.displayLocations[idx].ptType))
                                .frame(width: diameter, height: diameter)
                                .position(x: x(locationManager.displayLocations[idx], width: geometry.size.width),
                                          y: y(locationManager.displayLocations[idx], height: geometry.size.height))
                        }
//                        Circle()
//                            .fill(.blue)
//                            .frame(width: diameter, height: diameter)
//                            .position(x: x(center, width: geometry.size.width),
//                                      y: y(center, height: geometry.size.height))
                    }
                }
            }
        }
    }
    
    // =============== Main view ==========================
    
    func gpsView() -> some View {
        VStack {
            Text("GPS Reader").font(.title2).bold()
            //Spacer()
            //Text("Device Name: " + (self.persistence.getDeviceName()))
            if let message = locationManager.status {
                Spacer()
                //Text("Location: " + message)//.font(.)
                Text(message)//.font(.)
            }
            if let message = persistence.status {
                Spacer()
                Text("Persist Mgr: " + message).font(.caption)
            }
            if locationManager.currentLocation == nil {
                Spacer()
                Text("Start Location Manager")
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
                LocationPointsView(count: locationManager.stableLocationsCount)
                Spacer()
                HStack {
                    Spacer()
                    Button("Save Location") {
                        savePopup.toggle()
                    }
                    .disabled(!locationManager.locationIsStable)
                    .popover(isPresented: $savePopup) {
                        saveForm(location: locationManager.bestLocation!)
                    }
                    Spacer()
                    Button("Reset GPS") {
                        locationManager.reset()
                    }
                    Spacer()
                }
                
                VStack {
                    Slider(value: $stability, in: 1...10)
                    .onChange(of: stability) { newValue in
                        //print("Name changed to \(stability)!")
                        locationManager.requiredStabilityCounter = Int(stability)
                    }
                    Text("Required stability is \(stability, specifier: "%.0f")")
                }
                .padding()
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
