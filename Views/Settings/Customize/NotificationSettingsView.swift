//
//  NotificationSettingsView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 15/5/25.
//

import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("tasksNotificationEnabled") private var tasksNotificationEnabled = true
    @AppStorage("eventsNotificationEnabled") private var eventsNotificationEnabled = true
    @AppStorage("weatherNotificationEnabled") private var weatherNotificationEnabled = false
    @AppStorage("friendsNotificationEnabled") private var friendsNotificationEnabled = true
    @AppStorage("groupsNotificationEnabled") private var groupsNotificationEnabled = true
    @AppStorage("chatNotificationEnabled") private var chatNotificationEnabled = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    NotificationToggleRow(icon: "checkmark.circle.fill", title: "Tasks Notification", isOn: $tasksNotificationEnabled, color: .blue)
                    NotificationToggleRow(icon: "calendar.circle.fill", title: "Events Notification", isOn: $eventsNotificationEnabled, color: .orange)
                    NotificationToggleRow(icon: "cloud.sun.fill", title: "Weather Notification", isOn: $weatherNotificationEnabled, color: .mint)
                    NotificationToggleRow(icon: "person.crop.circle.fill", title: "Friends Notification", isOn: $friendsNotificationEnabled, color: .purple)
                    NotificationToggleRow(icon: "person.2.fill", title: "Groups Notification", isOn: $groupsNotificationEnabled, color: .green)
                    NotificationToggleRow(icon: "bubble.left.and.bubble.right.fill", title: "Chat Notification", isOn: $chatNotificationEnabled, color: .pink)
                }
                .padding()
            }
            .navigationTitle("Notifications ❀")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct NotificationToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    var color: Color

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .padding(10)
                .background(color)
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
}

#Preview {
    NotificationSettingsView()
}
