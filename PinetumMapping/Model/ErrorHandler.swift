import Foundation
import CoreLocation
import MapKit

class ErrorHandler : ObservableObject {
    static public let shared = ErrorHandler()

    @Published var error: String?
    var showingAlert = false
    
    func reportError(_ err: String) {
        DispatchQueue.main.async {
            self.error = err
            self.showingAlert = true
        }
    }

}
