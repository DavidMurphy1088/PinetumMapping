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
    @ObservedObject var deltas = LocationManager.shared.deltas
    
    @State private var savePopup = false
    @State private var savePopup1 = false
    @State private var locationName: String = ""
    @State private var addDirections = false
    @State var showingDeviceNamePopover = false
    @State var deviceName: String = ""
    @State private var stability: Double = 4
    
    func fmt(_ l: CLLocationCoordinate2D) -> String {
        return String(format: "%.5f", l.latitude)+",  "+String(format: "%.5f", l.longitude)
    }
    
    func saveForm(cords:CLLocationCoordinate2D?) -> some View {
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
                                id: UUID().uuidString,
                                locationName: locationName,
                                datetime: Date().timeIntervalSince1970,
                                lat: saveCords.latitude, lng: saveCords.longitude)
                            self.locations.addLocation(location: rec)
                            //locationManager.resetLastStableLocation()
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
    
    // =============== 2D plot ==========================

    struct LocationPointsView: View {
        @State var count: Int
        @ObservedObject var deltas = LocationManager.shared.deltas
        //@ObservedObject var center:Delta = LocationManager.shared.centerPlotPoint
        private let diameter = 12.0
        
        func scale(dimension: Double) -> Double {
            var max = 0.0
            for delta in deltas.deltas {
                if abs(delta.lat) > max {
                    max = abs(delta.lat)
                }
                if abs(delta.lng) > max {
                    max = abs(delta.lng)
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
        
        func x(_ delta: Delta, width: Double) -> Double {
            let offset = width/2.0
            let res = (scale(dimension: width) * delta.lat) + offset
            return res
        }
        
        func y(_ delta: Delta, height: Double) -> Double {
            let offset = height/2
            //let xs = locationManager.centerPlotPoint
            return scale(dimension: height) * delta.lng + offset
        }

        func color(_ plotType:Int) -> Color {
            switch plotType {
//            case 2:
//                return Color(.blue)
            case 1:
                return Color(.red)
            default:
                return Color(.green)
            }

        }
        
        var body: some View {
            GeometryReader { geometry in
                VStack {
                    ZStack {
                        //Rectangle().stroke(Color.gray, lineWidth: 3.0).frame(width: 300, height: 300, alignment: .center)
                        ForEach(0..<deltas.deltaCnt, id: \.self) { idx in
                            if deltas.deltas[idx].ptType >= 0 {
                                Circle()
                                    .fill(color(deltas.deltas[idx].ptType))
                                    .frame(width: diameter, height: diameter)
                                    .position(x: x(deltas.deltas[idx], width: geometry.size.width),
                                              y: y(deltas.deltas[idx], height: geometry.size.height))
                            }
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
                Text("Location: " + message)//.font(.)
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
                LocationPointsView(count: deltas.deltaCnt)
                Spacer()
                HStack {
                    Spacer()
                    Button("Save Location") {
                        savePopup.toggle()
                    }
                    .disabled(!locationManager.locationIsStable)
                    .popover(isPresented: $savePopup) {
                        saveForm(cords: locationManager.lastStableLocation)
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
