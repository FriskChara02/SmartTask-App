//
//  GoogleCalendarView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 17/4/25.
//

import SwiftUI
import GoogleAPIClientForREST_Calendar

struct GoogleCalendarView: View {
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var googleAuthVM: GoogleAuthViewModel
    @EnvironmentObject var googleCalendarService: GoogleCalendarService
    @Binding var showGoogleCalendar: Bool
    
    @State private var events: [GTLRCalendar_Event] = []
    @State private var errorMessage: String?
    @State private var selectedDate = Date()
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? .black.opacity(0.9) : .white,
                    colorScheme == .dark ? themeColor.opacity(0.2) : themeColor.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Google Calendar ⋆˚࿔")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            googleAuthVM.signOut()
                            showGoogleCalendar = false
                        }
                    }) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(themeColor)
                            .padding(10)
                            .background(colorScheme == .dark ? Color.gray.opacity(0.3) : .white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    Text("← Logout")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Date Picker
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .accentColor(themeColor)
                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : .white)
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding(.horizontal, 16)
                
                // Events List
                if googleAuthVM.isSignedIn {
                    if isLoading {
                        ProgressView()
                            .tint(themeColor)
                            .padding()
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 16) {
                            Text(errorMessage)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                            Button(action: {
                                fetchEvents(for: selectedDate)
                            }) {
                                Text("Thử lại ꕤ")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(themeColor)
                                    .cornerRadius(10)
                            }
                        }
                    } else if events.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("Không có sự kiện nào trong ngày này ✦")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .padding()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(0...23, id: \.self) { hour in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(hour % 12 == 0 ? 12 : hour % 12) \(hour < 12 ? "AM" : "PM")")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(colorScheme == .dark ? .gray.opacity(0.7) : .gray)
                                            .frame(width: 60, alignment: .leading)
                                            .padding(.top, 8)
                                        
                                        VStack(alignment: .leading) {
                                            Divider()
                                                .background(colorScheme == .dark ? .gray.opacity(0.5) : .gray.opacity(0.3))
                                            
                                            let eventsForHour = events.filter { event in
                                                guard let startDate = event.start?.dateTime?.date else { return false }
                                                let calendar = Calendar.current
                                                return calendar.component(.hour, from: startDate) == hour &&
                                                       calendar.isDate(startDate, inSameDayAs: selectedDate)
                                            }
                                            
                                            if eventsForHour.isEmpty {
                                                Text("Không có sự kiện ⟢")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(colorScheme == .dark ? .gray.opacity(0.8) : .gray.opacity(0.6))
                                                    .padding(.vertical, 8)
                                            } else {
                                                ForEach(eventsForHour, id: \.identifier) { event in
                                                    EventRow(event: event)
                                                        .padding(.vertical, 4)
                                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(colorScheme == .dark ? Color.gray.opacity(0.2) : .white)
                        .cornerRadius(12)
                        .padding(.horizontal, 8)
                        .shadow(radius: 4)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(colorScheme == .dark ? .gray.opacity(0.8) : .gray)
                        Text("Vui lòng đăng nhập để xem sự kiện Google Calendar ⟡")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .gray.opacity(0.8) : .gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .onAppear {
                        withAnimation(.spring()) {
                            showGoogleCalendar = false
                        }
                    }
                }
            }
            .onAppear {
                if googleAuthVM.isSignedIn {
                    fetchEvents(for: selectedDate)
                    // Xóa sự kiện trùng lặp một lần
                    GoogleCalendarService.shared.deleteEvent(eventId: "tlivu0r3jvt2k39djj2h6gqogs") { result in
                        switch result {
                        case .success:
                            print("✅ Deleted duplicate Google Calendar event: tlivu0r3jvt2k39djj2h6gqogs")
                        case .failure(let error):
                            print("❌ Failed to delete duplicate event: \(error)")
                        }
                    }
                } else {
                    showGoogleCalendar = false
                }
            }
            .onChange(of: googleAuthVM.isSignedIn) { _, isSignedIn in
                if isSignedIn {
                    fetchEvents(for: selectedDate)
                } else {
                    events = []
                    showGoogleCalendar = false
                }
            }
            .onChange(of: selectedDate) { _, newDate in
                if googleAuthVM.isSignedIn {
                    fetchEvents(for: newDate)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .fetchEventsForDate)) { notification in
                if let userInfo = notification.userInfo, let date = userInfo["date"] as? Date {
                    selectedDate = date
                    fetchEvents(for: date)
                }
            }
        }
    }
    
    // MARK: - Fetch Events
    private func fetchEvents(for date: Date) {
        isLoading = true
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        GoogleCalendarService.shared.fetchEvents(from: startOfDay, to: endOfDay) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let fetchedEvents):
                    self.events = fetchedEvents
                    self.errorMessage = nil
                    print("✅ Fetched \(fetchedEvents.count) events for \(date)")
                case .failure(let error):
                    self.errorMessage = "Không thể tải sự kiện: \(error.localizedDescription)"
                    self.events = []
                    print("❌ UI error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Event Row
    private func EventRow(event: GTLRCalendar_Event) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        
        return HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(themeColor)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.summary ?? "Không có tiêu đề")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                if let start = event.start?.dateTime?.date, let end = event.end?.dateTime?.date {
                    Text("\(formatter.string(from: start)) - \(formatter.string(from: end))")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? .gray.opacity(0.8) : .secondary)
                }
                
                if let description = event.descriptionProperty {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? .gray.opacity(0.8) : .gray)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color.gray.opacity(0.3) : .white,
                    colorScheme == .dark ? themeColor.opacity(0.2) : themeColor.opacity(0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(10)
        .shadow(color: .gray.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 8)
    }
}

#Preview {
    GoogleCalendarView(showGoogleCalendar: .constant(true))
        .environment(\.themeColor, .blue)
        .environmentObject(GoogleAuthViewModel())
        .environmentObject(GoogleCalendarService.shared)
        .preferredColorScheme(.dark)
}
