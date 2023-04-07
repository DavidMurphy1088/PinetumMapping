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
    @State var pictureSet:PictureSet = PictureSet(pictures: [])
    @StateObject var cameraModel = CameraModel()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                Text("Save Location").font(.title2).bold()
                if let message = MessageHandler.shared.status {
                    Text(message)
                }
                TextField("location name", text: $locationName)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .padding()
                if let photo = cameraModel.photo {
                    if let im = photo.image {
                        VStack {
                            HStack {
                                NavigationLink("Change Picture") {
                                    //TODO very slow to go to view...
                                    CameraTakePictureView(model: cameraModel, pictureSet: pictureSet)
                                }
                                .padding()
                                Button("Remove Picture") {
                                    cameraModel.removePicture()
                                    pictureSet.pictures.removeAll()
                                }
                                .padding()
                            }
                            Image(uiImage: im)
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(contentMode: .fit)
                            //.frame(width: CGFloat(im.size), alignment: .topLeading)
                                .border(.blue)
                        }
                    }
                }
                else {
                    Spacer()
                    NavigationLink("Add Picture") {
                        CameraTakePictureView(model: cameraModel, pictureSet: pictureSet)
                    }
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button("Cancel") {
                        dismiss()
                    }
                    Spacer()
                    Button("Save") {
                        print("Pics", pictureSet.pictures.count)
                        let location = LocationRecord(
                            id: UUID().uuidString,
                            locationName: locationName,
                            datetime: Date().timeIntervalSince1970,
                            lat: location.latitude, lng: location.longitude,
                            pictureSet: pictureSet)
                        LocationRecords.shared.addLocation(location: location)
                        dismiss()
                    }
                    .disabled(locationName.count == 0)
                    Spacer()
                }
                .padding()
            }
        }
    }
}
