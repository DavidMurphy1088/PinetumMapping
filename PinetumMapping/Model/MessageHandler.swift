import Foundation
import CoreLocation
import MapKit

class MessageHandler : ObservableObject {
    static public let shared = MessageHandler()
    @Published var error: String?
    var showingAlert = false
    @Published var status: String?

    func reportError(context:String, _ err: String) {
        DispatchQueue.main.async {
            self.error = context + " " + err
            self.showingAlert = true
        }
    }
    
    func setStatus(_ status: String) {
        DispatchQueue.main.async {
            self.status = status
        }
    }

}
