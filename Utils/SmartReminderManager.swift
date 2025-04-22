//
//  SmartReminderManager.swift
//  SmartTask
//
//  Created by Loi Nguyen on 6/4/25.
//

import Foundation
import UserNotifications

class SmartReminderManager {
    static let shared = SmartReminderManager()
    
    private init() {}
    
    func scheduleReminder(for event: EventModel, minutesBefore: Int = -30, message: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "📌 Nhắc nhở sự kiện"
        content.body = message ?? "Bạn có sự kiện: \(event.title) lúc \(formattedTime(from: event.startDate))"
        content.sound = .default
        
        let triggerDate = Calendar.current.date(byAdding: .minute, value: minutesBefore, to: event.startDate) ?? event.startDate
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "event_\(event.id)_\(minutesBefore)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if error == nil {
                print("✅ Đã tạo nhắc nhở cho sự kiện: \(event.title) trước \(minutesBefore) phút")
            }
        }
    }

    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Xóa các nhắc nhở cũ của sự kiện
    public func removeExistingReminders(for event: EventModel) {
        let reminderIds = [
            "event_\(event.id)_-1440",
            "event_\(event.id)_-60",
            "event_\(event.id)_-5"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIds)
        print("🗑️ Đã xóa các nhắc nhở cũ cho sự kiện: \(event.title)")
    }
}
