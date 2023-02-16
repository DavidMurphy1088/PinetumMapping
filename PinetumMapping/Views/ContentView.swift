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
    @State private var stability: Double = 5
    
    func fmt(_ l: CLLocationCoordinate2D) -> String {
        return String(format: "%.5f", l.latitude)+",  "+String(format: "%.5f", l.longitude)
    }
    
    func saveForm(cords:CLLocationCoordinate2D?) -> some View {
        Form {
            VStack {
                VStack(alignment: .center) {
                    Text("Save Location").font(.title2).bold()
                    if let message = locationManager.status {
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
                                id: UUID().uuidString,
                                locationName: locationName,
                                datetime: Date().timeIntervalSince1970,
                                lat: saveCords.latitude, lng: saveCords.longitude)
                            self.locations.addLocation(location: rec)
                            //self.locationManager.currentLocation = nil
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
    
    // =============== 2D plot ==========================

    struct PlotShape: Shape {
        @State var count: Int

        var diameter = 10.0

        @ObservedObject var deltas = LocationManager.shared.deltas

        func path(in rect: CGRect) -> Path {
            var path = Path()
            var max = 0.0
            for delta in deltas.deltas {
                if delta.lat > max {
                    max = delta.lat
                }
                if delta.lng > max {
                    max = delta.lng
                }
            }
            var scale = Double(rect.width) / max
            scale = scale/2.0
            print ("===>=====>", deltas.deltaCnt, scale, rect.width)
            for i in 0..<count {
                let pt = CGPoint(x: deltas.deltas[i].lat*scale, y: deltas.deltas[i].lat*scale)
                path.move(to: CGPoint(x: rect.width/2, y:rect.height/2))
                path.addLine(to: pt)
                path.addEllipse(in: CGRect(x: pt.x, y: pt.y, width: diameter, height: diameter))
            }
            return path
        }
    }

    struct PlotView: View {
        @State var count: Int
        @ObservedObject var deltas = LocationManager.shared.deltas

        var body: some View {
            VStack {
                ZStack {
                    Rectangle()
                        .stroke(Color.gray, lineWidth: 3.0)
                        .frame(width: 300, height: 300, alignment: .center)
                    Text("PV=\(deltas.deltaCnt)")
                    PlotShape(count: deltas.deltaCnt)
                        .stroke(Color.red, lineWidth: 2.0)
                        //.frame(width: 300, height: 300, alignment: .center)
                }
                Spacer()
            }
        }
    }
    
    // =============== Main view ==========================
    
    func gpsView() -> some View {
        VStack {
            Text("GPS Reader").font(.title2).bold()
            Spacer()
            Text("Device Name: " + (self.persistence.getDeviceName()))
            if let message = locationManager.status {
                Spacer()
                Text("Location Mgr: " + message).font(.caption)
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
                Text("View ====\(deltas.deltaCnt)")
                PlotView(count: deltas.deltaCnt)
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
                VStack {
                    Slider(value: $stability, in: 1...20)
                    .onChange(of: stability) { newValue in
                        print("Name changed to \(stability)!")
                        locationManager.requiredStability = Int(stability)
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
