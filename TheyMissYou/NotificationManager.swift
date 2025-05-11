import SwiftUI
import UserNotifications

enum NotificationFrequency: Double, CaseIterable {
    case immediate = 5 // 5 seconds for testing
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    
    var description: String {
        switch self {
        case .immediate: return "5 seconds"
        case .oneMinute: return "1 minute"
        case .fiveMinutes: return "5 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        }
    }
}

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupNotificationCategories()
    }
    
    private func setupNotificationCategories() {
        // Create the custom actions
        let openAction = UNNotificationAction(
            identifier: "OPEN_ACTION",
            title: "Open",
            options: .foreground
        )
        
        // Create the category
        let category = UNNotificationCategory(
            identifier: "POST_PHOTO",
            actions: [openAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval) {
        // Remove any pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["destination": "postPhoto"]
        content.categoryIdentifier = "POST_PHOTO"
        
        // Add app icon as attachment if available
        if let attachment = prepareNotificationIcon() {
            content.attachments = [attachment]
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully for \(timeInterval) seconds from now")
            }
        }
    }
    
    private func prepareNotificationIcon() -> UNNotificationAttachment? {
        guard let iconImage = UIImage(named: "logo"),
              let data = iconImage.pngData() else { return nil }
        
        let tempDir = FileManager.default.temporaryDirectory
        let identifier = UUID().uuidString
        let fileURL = tempDir.appendingPathComponent("\(identifier).png")
        
        do {
            try data.write(to: fileURL)
            return try UNNotificationAttachment(identifier: identifier, url: fileURL)
        } catch {
            print("Error preparing notification icon: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if userInfo["destination"] as? String == "postPhoto" {
            NotificationCenter.default.post(name: NSNotification.Name("ShowPostPhotoView"), object: nil)
        }
        
        completionHandler()
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
} 