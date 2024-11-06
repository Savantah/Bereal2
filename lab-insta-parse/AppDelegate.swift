import UIKit
import UIKit
import ParseSwift
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
       
        ParseSwift.initialize(
            applicationId: "Xd25OOm8ugydh6jqFMagKGybRzcDX7On0FVHo2rJ",
            clientKey: "J9dncqJW6iO4iVJxlE2FjCSJ8xJMTNJLa5Tj61et",
            serverURL: URL(string: "https://parseapi.back4app.com")!
        )
        
        
        UNUserNotificationCenter.current().delegate = self
        
        
        NotificationManager.shared.requestNotificationAuthorization()
        
        return true
    }
    
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
   
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == "bereal.periodic" {
            NotificationCenter.default.post(name: Notification.Name("OpenCamera"), object: nil)
        }
        completionHandler()
    }

   
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
