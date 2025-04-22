//
//  AddEventView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 17/4/25.
//

import SwiftUI
import GoogleSignIn

struct AddEventView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var googleAuthVM: GoogleAuthViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColor) var themeColor
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date?
    @State private var priority = "Medium"
    @State private var isAllDay = false
    @State private var showConflictAlert = false
    @State private var hasConflict = false
    @State private var errorMessage: String?
    @State private var isCreatingEvent = false // Ngăn tap lặp
    @State private var showErrorAlert = false // Trạng thái để hiển thị Alert cho errorMessage
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin sự kiện ✎ᝰ.").font(.system(size: 16, weight: .medium, design: .rounded))) {
                    TextField("Tiêu đề", text: $title)
                        .font(.system(size: 16, design: .rounded))
                        .padding(.vertical, 5)
                        .background(Color(UIColor.systemFill))
                        .cornerRadius(8)
                    
                    TextField("Mô tả", text: $description)
                        .font(.system(size: 16, design: .rounded))
                        .padding(.vertical, 5)
                        .background(Color(UIColor.systemFill))
                        .cornerRadius(8)
                }
                
                Section(header: Text("Thời gian ｡ ₊°༺✧༻°₊ ｡").font(.system(size: 16, weight: .medium, design: .rounded))) {
                    DatePicker("Bắt đầu", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    
                    DatePicker("Kết thúc", selection: Binding(
                        get: { endDate ?? startDate },
                        set: { endDate = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    
                    Toggle(isOn: $isAllDay) {
                        Text("Cả ngày")
                            .font(.system(size: 16, design: .rounded))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: themeColor))
                }
                
                Section(header: Text("Ưu tiên 𓆩♡𓆪").font(.system(size: 16, weight: .medium, design: .rounded))) {
                    Picker("Ưu tiên", selection: $priority) {
                        Text("Low").tag("Low")
                        Text("Medium").tag("Medium")
                        Text("High").tag("High")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Thêm sự kiện ✦")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        guard !isCreatingEvent else { return }
                        isCreatingEvent = true
                        
                        guard let userId = authVM.currentUser?.id else {
                            errorMessage = "Không tìm thấy userId"
                            print("❌ Không tìm thấy userId")
                            isCreatingEvent = false
                            return
                        }
                        errorMessage = nil
                        if googleAuthVM.isSignedIn {
                            // Kiểm tra xung đột với Google Calendar
                            GoogleCalendarService.shared.checkConflict(startDate: startDate, endDate: endDate ?? startDate) { result in
                                switch result {
                                case .success(let conflict):
                                    hasConflict = conflict
                                    if conflict {
                                        showConflictAlert = true
                                    } else {
                                        saveEvent(userId: userId)
                                    }
                                case .failure(let error):
                                    print("❌ Failed to check conflict: \(error.localizedDescription)")
                                    errorMessage = "Không thể kiểm tra xung đột lịch: \(error.localizedDescription)"
                                    isCreatingEvent = false
                                    showErrorAlert = true // Hiển thị Alert cho lỗi Google Calendar
                                }
                            }
                        } else {
                            saveEvent(userId: userId)
                        }
                    }) {
                        Text("Lưu ❀")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(LinearGradient(gradient: Gradient(colors: [themeColor, .purple]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(20)
                            .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    .disabled(title.isEmpty || isCreatingEvent)
                }
            }
            .onAppear {
                let now = Date()
                if let suggestedStart = eventVM.suggestFreeTimeSlot(on: now) {
                    startDate = suggestedStart
                    endDate = Calendar.current.date(byAdding: .hour, value: 1, to: suggestedStart)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .dismissAddEvent)) { _ in
                dismiss()
            }
            .onChange(of: eventVM.errorMessage) { oldValue, newValue in
                showErrorAlert = newValue != nil
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Lỗi"),
                    message: Text(eventVM.errorMessage ?? errorMessage ?? "Đã xảy ra lỗi không xác định"),
                    dismissButton: .default(Text("OK")) {
                        eventVM.errorMessage = nil // Xóa errorMessage của EventViewModel
                        errorMessage = nil // Xóa errorMessage cục bộ
                        isCreatingEvent = false // Cho phép thử lại
                    }
                )
            }
            .alert(isPresented: $showConflictAlert) {
                Alert(
                    title: Text("Xung đột lịch ✧.*"),
                    message: Text("Sự kiện này trùng với một sự kiện trên Google Calendar. Bạn có muốn tiếp tục lưu không?"),
                    primaryButton: .default(Text("Tiếp tục")) {
                        if let userId = authVM.currentUser?.id {
                            saveEvent(userId: userId)
                        }
                    },
                    secondaryButton: .cancel(Text("Hủy")) {
                        hasConflict = false
                        isCreatingEvent = false
                    }
                )
            }
        }
    }
    
    private func saveEvent(userId: Int) {
        let newEvent = EventModel(
            id: Int.random(in: 1000...9999),
            userId: userId,
            title: title,
            description: description.isEmpty ? nil : description,
            startDate: startDate,
            endDate: endDate,
            priority: priority,
            isAllDay: isAllDay,
            createdAt: Date(),
            updatedAt: Date(),
            googleEventId: nil
        )
        
        withAnimation(.spring()) {
            if googleAuthVM.isSignedIn {
                // Tạo sự kiện trên Google Calendar
                GoogleCalendarService.shared.createEvent(
                    title: title,
                    startDate: startDate,
                    endDate: endDate,
                    description: description
                ) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let eventId):
                            print("✅ Successfully created Google Calendar event with ID: \(eventId)")
                            let updatedEvent = EventModel(
                                id: newEvent.id,
                                userId: newEvent.userId,
                                title: newEvent.title,
                                description: newEvent.description,
                                startDate: newEvent.startDate,
                                endDate: newEvent.endDate,
                                priority: newEvent.priority,
                                isAllDay: newEvent.isAllDay,
                                createdAt: newEvent.createdAt,
                                updatedAt: newEvent.updatedAt,
                                googleEventId: eventId
                            )
                            eventVM.addEvent(event: updatedEvent)
                            // Delay fetch để đảm bảo đồng bộ
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                NotificationCenter.default.post(name: .fetchEventsForDate, object: nil, userInfo: ["date": startDate])
                            }
                            isCreatingEvent = false
                            dismiss()
                        case .failure(let error):
                            print("❌ Failed to create Google Calendar event: \(error)")
                            self.errorMessage = "Không thể tạo sự kiện trên Google Calendar: \(error.localizedDescription)"
                            eventVM.addEvent(event: newEvent) // Vẫn lưu sự kiện cục bộ
                            isCreatingEvent = false
                            showErrorAlert = true // Hiển thị Alert cho lỗi Google Calendar
                        }
                    }
                }
            } else {
                eventVM.addEvent(event: newEvent)
                // Không gọi dismiss() ở đây vì nếu có xung đột, addEvent sẽ đặt errorMessage và hiển thị Alert
                // Chỉ dismiss nếu không có lỗi, được xử lý trong onReceive(.dismissAddEvent)
                isCreatingEvent = false
            }
        }
    }
}

#Preview {
    let googleAuthVM = GoogleAuthViewModel()
    let eventVM = EventViewModel(googleAuthVM: googleAuthVM)
    let authVM = AuthViewModel()
    authVM.currentUser = UserModel(
        id: 7,
        name: "Tester01",
        email: "Test01",
        password: "123",
        avatarURL: nil,
        description: "I’m still newbie.",
        dateOfBirth: Date(),
        location: "Cat Islands",
        joinedDate: nil,
        gender: "Nam",
        hobbies: "Love Cats",
        bio: "Halo"
    )

    return AddEventView()
        .environmentObject(eventVM)
        .environmentObject(authVM)
        .environmentObject(googleAuthVM)
        .environment(\.themeColor, .blue)
}
