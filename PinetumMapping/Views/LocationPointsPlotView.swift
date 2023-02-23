import SwiftUI
import CoreData
import SwiftUI
import CoreLocation
import CoreLocationUI
import CoreLocation
import UIKit
import FirebaseAnalyticsSwift
// =============== 2D plot ==========================

struct LocationPointsPlotView: View {
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
    
    func x(_ location: StableGPSLocation, width: Double) -> Double {
        let offset = width/2.0
        //let center = locationManager.stableLocations.locations[0]
        let res = (scale(dimension: width) * (location.latitude)) + offset
        return res
    }
    
    func y(_ location: StableGPSLocation, height: Double) -> Double {
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

