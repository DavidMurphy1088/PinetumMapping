import SwiftUI
import CoreData
import SwiftUI
import CoreLocation
import CoreLocationUI
import CoreLocation
import UIKit
import FirebaseAnalyticsSwift

struct SaveLocationView : View {
    @Environment(\.dismiss) private var dismiss
    @State var location:CLLocationCoordinate2D
    @State var locationManager = LocationManager.shared
    @State var locationName: String = ""
    @State var cameraIsDisabled = true
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Save Location").font(.title2).bold()
            if let message = locationManager.status {
                Text(message)
            }
            TextField("location name", text: $locationName)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .padding()
            Button(cameraIsDisabled ? "Add Picture" : "Remove Picture") {
                cameraIsDisabled.toggle()
            }
            if !cameraIsDisabled {
                CameraView()
            }
            Spacer()
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    let location = LocationRecord(
                        id: UUID().uuidString,
                        locationName: locationName,
                        datetime: Date().timeIntervalSince1970,
                        lat: location.latitude, lng: location.longitude)
                    //LocationRecords.shared.addLocation(location: location)
                    //                        if resetGPS {
                    //                            locationManager.reset()
                    //                        }
                }
                .disabled(locationName.count == 0)
                Spacer()
            }
            Spacer()
        }
    }
}
