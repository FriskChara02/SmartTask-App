import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.themeColor) var themeColor
    @EnvironmentObject var googleAuthVM: GoogleAuthViewModel // ✅ Theo dõi trạng thái Google Calendar
    
    let event: EventModel
    @State private var isEditing = false
    @State private var animate = false
    
    @State private var editedTitle = ""
    @State private var editedDescription = ""
    @State private var editedStartDate = Date()
    @State private var editedEndDate: Date?
    @State private var editedPriority = "Medium"
    @State private var editedIsAllDay = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isEditing {
                        editingSection
                    } else {
                        viewingSection
                    }
                    actionButtons
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .navigationTitle(isEditing ? "Chỉnh sửa sự kiện ⟡" : "Chi tiết sự kiện ✦")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isEditing {
                        Button(action: {
                            withAnimation(.easeInOut) {
                                loadEventForEditing()
                                isEditing = true
                            }
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(themeColor)
                                .font(.title3)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button(action: {
                            withAnimation(.easeInOut) {
                                isEditing = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeColor)
                                .font(.title3)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Viewing Section
    private var viewingSection: some View {
        VStack(spacing: 20) {
            Text(event.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .scaleEffect(animate ? 1.0 : 0.95)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.5)) {
                        animate = true
                    }
                }
            
            if let description = event.description {
                Text(description)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            infoRow(icon: "calendar", text: "Bắt đầu: \(dateFormatter.string(from: event.startDate))", color: .blue)
            
            if let endDate = event.endDate {
                infoRow(icon: "calendar", text: "Kết thúc: \(dateFormatter.string(from: endDate))", color: .yellow)
            }
            
            infoRow(icon: "exclamationmark.triangle", text: "Ưu tiên: \(event.priority)", color: priorityColor(event.priority))
            
            infoRow(icon: "clock", text: event.isAllDay ? "Cả ngày" : "Không cả ngày", color: .purple)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Editing Section
    private var editingSection: some View {
        VStack(spacing: 20) {
            TextField("Tiêu đề", text: $editedTitle)
                .font(.system(size: 18, design: .rounded))
                .padding()
                .background(Color(UIColor.systemFill))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.3), lineWidth: 1))
            
            TextField("Mô tả", text: $editedDescription)
                .font(.system(size: 16, design: .rounded))
                .padding()
                .background(Color(UIColor.systemFill))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.3), lineWidth: 1))
            
            DatePicker("Bắt đầu", selection: $editedStartDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .padding(.vertical, 5)
            
            DatePicker("Kết thúc", selection: Binding(
                get: { editedEndDate ?? editedStartDate },
                set: { editedEndDate = $0 }
            ), displayedComponents: [.date, .hourAndMinute])
            .datePickerStyle(.compact)
            .padding(.vertical, 5)
            
            Picker("Ưu tiên", selection: $editedPriority) {
                Text("Low").tag("Low")
                Text("Medium").tag("Medium")
                Text("High").tag("High")
            }
            .pickerStyle(SegmentedPickerStyle())
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Toggle(isOn: $editedIsAllDay) {
                Text("Cả ngày")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
            }
            .toggleStyle(SwitchToggleStyle(tint: .purple))
            
            Button(action: {
                let updatedEvent = EventModel(
                    id: event.id,
                    userId: event.userId,
                    title: editedTitle,
                    description: editedDescription.isEmpty ? nil : editedDescription,
                    startDate: editedStartDate,
                    endDate: editedEndDate,
                    priority: editedPriority,
                    isAllDay: editedIsAllDay,
                    createdAt: event.createdAt,
                    updatedAt: Date()
                )
                eventVM.updateEvent(event: updatedEvent)
                withAnimation(.easeInOut) {
                    isEditing = false
                    dismiss()
                }
            }) {
                Text("✎ Sửa")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                    .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button(action: {
                withAnimation(.spring()) {
                    eventVM.markEventCompleted(eventId: event.id)
                    // Không dismiss ngay, chờ Notification
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Hoàn thành")
                }
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [.green, .teal]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(12)
                .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
            }
            
            Button(action: {
                withAnimation(.spring()) {
                    eventVM.deleteEvent(eventId: event.id)
                    dismiss()
                }
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Xóa")
                }
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(12)
                .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
            }
            
            // Thêm nút Add to Google Calendar
            Button(action: {
                GoogleCalendarService.shared.createEvent(
                    title: event.title,
                    startDate: event.startDate,
                    endDate: event.endDate,
                    description: event.description
                ) { result in
                    switch result {
                    case .success(let eventId):
                        print("Added to Google Calendar with ID: \(eventId)")
                        // Cập nhật googleEventId trong database
                        let updatedEvent = EventModel(
                            id: event.id,
                            userId: event.userId,
                            title: event.title,
                            description: event.description,
                            startDate: event.startDate,
                            endDate: event.endDate,
                            priority: event.priority,
                            isAllDay: event.isAllDay,
                            createdAt: event.createdAt,
                            updatedAt: Date(),
                            googleEventId: eventId
                        )
                        eventVM.updateEvent(event: updatedEvent)
                    case .failure(let error):
                        print("Failed to add to Google Calendar: \(error)")
                    }
                }
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Add to Google Calendar")
                }
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [themeColor, .purple]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(12)
                .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
                .opacity(googleAuthVM.isSignedIn ? 1.0 : 0.5) // Mờ khi chưa sync
            }
            .disabled(!googleAuthVM.isSignedIn) // Vô hiệu nếu chưa đăng nhập Google
        }
        .padding(.horizontal)
        .onReceive(NotificationCenter.default.publisher(for: .dismissAddEvent)) { _ in
            dismiss() // Đóng sheet khi nhận thông báo từ markEventCompleted
        }
    }
    
    // MARK: - Helpers
    private func loadEventForEditing() {
        editedTitle = event.title
        editedDescription = event.description ?? ""
        editedStartDate = event.startDate
        editedEndDate = event.endDate
        editedPriority = event.priority
        editedIsAllDay = event.isAllDay
    }
    
    private func infoRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))
            Text(text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        default: return .blue
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    let event = EventModel(
        id: 1,
        userId: 1,
        title: "Cuộc họp nhóm",
        description: "Thảo luận dự án",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        priority: "High",
        isAllDay: false,
        createdAt: Date(),
        updatedAt: Date()
    )
    EventDetailView(event: event)
        .environmentObject(EventViewModel(googleAuthVM: GoogleAuthViewModel()))
        .environmentObject(GoogleAuthViewModel())
}
