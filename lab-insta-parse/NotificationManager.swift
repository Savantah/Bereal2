
import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
                self.scheduleRandomDailyNotification()
            } else {
                print("❌ Notification permission denied")
            }
        }
    }
    
    func scheduleRandomDailyNotification() {
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        
        let calendar = Calendar.current
        let now = Date()
        
     
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return }
        
        
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = Int.random(in: 8...22) // Random hour between 8 AM and 10 PM
        components.minute = Int.random(in: 0...59)
        
        
        let content = UNMutableNotificationContent()
        content.title = "⚡️ Time to BeReal!"
        content.body = "2 min left to capture a moment and share it with your friends!"
        content.sound = .default
        
    
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
     
        let request = UNNotificationRequest(
            identifier: "bereal.daily",
            content: content,
            trigger: trigger
        )
        
      
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Notification scheduled for \(components)")
            }
        }
    }
}
