import Foundation
import CoreLocation
import MapKit

class Util {
    
    static func fmtDatetime(datetime : TimeInterval) -> String {
        let dt  = Date(timeIntervalSince1970:datetime)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MMM-dd HH:mm"
        let dateString = formatter.string(from: dt)
        return dateString
    }
}
