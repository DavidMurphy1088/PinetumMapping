import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    print("========== didFinishLaunchingWithOptions, Firebase configure")
    return true
  }
}

@main
struct PinetumMappingApp: App {
    let persistenceController = PersistenceController.shared
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}


//@main
//struct YourApp: App {
//  // register app delegate for Firebase setup
//  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//
//
//  var body: some Scene {
//    WindowGroup {
//      NavigationView {
//        ContentView()
//      }
//    }
//  }
//}