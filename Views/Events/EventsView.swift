import SwiftUI
import GoogleSignIn

struct EventsView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.themeColor) var themeColor
    @EnvironmentObject var googleAuthVM: GoogleAuthViewModel // ✅ Theo dõi trạng thái Google Calendar
    
    @State private var showingAddEvent = false
    @State private var selectedEvent: EventModel?
    @State private var showYourEvents = true
    @State private var showSpecialEvents = true
    @State private var showCompletedEvents = true
    @State private var isLoading = true // ^^ [NEW] Theo dõi trạng thái tải
    
    // Các ngày lễ đặc biệt ở Việt Nam
    private let specialEvents: [EventModel] = [
        EventModel(id: 1001, userId: 0, title: "Lễ Valentine", description: "Ngày lễ tình nhân", startDate: createDate(year: 2025, month: 2, day: 14), endDate: nil, priority: "Medium", isAllDay: true, createdAt: Date(), updatedAt: Date()),
        EventModel(id: 1002, userId: 0, title: "Quốc tế Phụ nữ", description: "Ngày 8/3", startDate: createDate(year: 2025, month: 3, day: 8), endDate: nil, priority: "Medium", isAllDay: true, createdAt: Date(), updatedAt: Date()),
        EventModel(id: 1003, userId: 0, title: "Giỗ Tổ Hùng Vương", description: "Ngày 10/3 âm lịch", startDate: createDate(year: 2025, month: 4, day: 7), endDate: nil, priority: "High", isAllDay: true, createdAt: Date(), updatedAt: Date()),
        EventModel(id: 1004, userId: 0, title: "Quốc tế Thiếu nhi", description: "Ngày 1/6", startDate: createDate(year: 2025, month: 6, day: 1), endDate: nil, priority: "Low", isAllDay: true, createdAt: Date(), updatedAt: Date()),
        EventModel(id: 1005, userId: 0, title: "Tết Trung Thu", description: "Rằm tháng 8 âm lịch", startDate: createDate(year: 2025, month: 9, day: 21), endDate: nil, priority: "Medium", isAllDay: true, createdAt: Date(), updatedAt: Date()),
        EventModel(id: 1006, userId: 0, title: "Tết Nguyên Đán", description: "Mùng 1 Tết 2025", startDate: createDate(year: 2025, month: 1, day: 29), endDate: nil, priority: "High", isAllDay: true, createdAt: Date(), updatedAt: Date()),
        EventModel(id: 1007, userId: 0, title: "Ngày Quốc khánh", description: "Ngày độc lập Việt Nam (2/9)", startDate: createDate(year: 2025, month: 9, day: 2), endDate: nil, priority: "High", isAllDay: true, createdAt: Date(), updatedAt: Date()),
        EventModel(id: 1008, userId: 0, title: "Ngày Nhà giáo Việt Nam", description: "Ngày 20/11", startDate: createDate(year: 2025, month: 11, day: 20), endDate: nil, priority: "Medium", isAllDay: true, createdAt: Date(), updatedAt: Date()),
        EventModel(id: 1009, userId: 0, title: "Ngày Phụ nữ Việt Nam", description: "Ngày 20/10", startDate: createDate(year: 2025, month: 10, day: 20), endDate: nil, priority: "Medium", isAllDay: true, createdAt: Date(), updatedAt: Date())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                if isLoading { // ^^ [NEW] Hiển thị khi đang tải
                    ProgressView("Đang tải sự kiện...")
                        .progressViewStyle(.circular)
                        .foregroundColor(themeColor)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Your Events
                            DisclosureGroup(isExpanded: $showYourEvents) {
                                ForEach(eventVM.events.sorted(by: { $0.startDate < $1.startDate }), id: \.id) { event in // ^^ [NEW] Sử dụng id: \.id để tránh trùng lặp
                                    Button(action: {
                                        withAnimation(.easeInOut) {
                                            selectedEvent = event
                                        }
                                    }) {
                                        EventCard(event: event)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(themeColor)
                                    Text("Your Events                                ⸜(｡˃ ᵕ ˂ )⸝")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Special Events
                            DisclosureGroup(isExpanded: $showSpecialEvents) {
                                ForEach(specialEvents, id: \.id) { event in // ^^ [NEW] Thêm id: \.id cho rõ ràng
                                    Button(action: {
                                        withAnimation(.easeInOut) {
                                            selectedEvent = event
                                        }
                                    }) {
                                        EventCard(event: event)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(themeColor)
                                    Text("Special Events                      ♡ (˶˃ ᵕ ˂˶)")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Completed Events
                            DisclosureGroup(isExpanded: $showCompletedEvents) {
                                ForEach(eventVM.completedEvents, id: \.id) { event in // ^^ [NEW] Thêm id: \.id để tránh trùng lặp
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 16))
                                        EventCard(event: event)
                                            .opacity(0.5)
                                        Spacer()
                                        Button(action: {
                                            withAnimation {
                                                eventVM.deleteEvent(eventId: event.id)
                                                eventVM.completedEvents.removeAll { $0.id == event.id }
                                            }
                                        }) {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 16))
                                        }
                                    }
                                }
                                if !eventVM.completedEvents.isEmpty {
                                    Button(action: {
                                        withAnimation {
                                            eventVM.completedEvents.forEach { eventVM.deleteEvent(eventId: $0.id) }
                                            eventVM.completedEvents.removeAll()
                                        }
                                    }) {
                                        Text("Xóa tất cả")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.red)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .padding(.top, 10)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(themeColor)
                                    Text("Events Completed                  (⸝⸝> ᴗ•⸝⸝)")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Sự kiện •⩊•")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring()) {
                            showingAddEvent = true
                        }
                    }) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView()
                    .environmentObject(eventVM)
                    .environmentObject(authVM)
                    .environmentObject(googleAuthVM) // ✅ Truyền googleAuthVM để kiểm tra xung đột
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
                    .environmentObject(eventVM)
            }
            .onAppear {
                // ^^ [NEW] Kiểm tra trạng thái đăng nhập trước khi fetch
                if authVM.isAuthenticated, let userId = authVM.currentUser?.id {
                    eventVM.fetchEvents(forUserId: userId)
                    print("📋 Rendering EventsView with \(eventVM.events.count) events: \(eventVM.events.map { $0.title })") // ^^ [NEW] Thêm log để debug
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // ^^ [NEW] Chờ API hoàn tất
                        self.isLoading = false
                        print("✅ Finished loading events: \(eventVM.events.count) events") // ^^ [NEW] Log xác nhận
                    }
                } else {
                    self.isLoading = false
                    print("⚠️ Chưa đăng nhập, không thể tải sự kiện")
                }
            }
            .alert(isPresented: Binding(
                get: { eventVM.errorMessage != nil },
                set: { if !$0 { eventVM.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Lỗi"),
                    message: Text(eventVM.errorMessage ?? "Đã xảy ra lỗi"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        default: return .blue
        }
    }
    
    private static func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}

struct EventCard: View {
    let event: EventModel
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(priorityColor(event.priority))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(dateFormatter.string(from: event.startDate))
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(priorityColor(event.priority))
                .font(.system(size: 16))
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 3)
        .padding(.vertical, 5)
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
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    let googleAuthVM = GoogleAuthViewModel()
    let eventVM = EventViewModel(googleAuthVM: googleAuthVM)
    let authVM = AuthViewModel()
    authVM.currentUser = UserModel(id: 7, name: "Tester01", email: "Test01", password: "123", avatarURL: nil, description: "I’m still newbie.", dateOfBirth: Date(), location: "Cat Islands", joinedDate: nil, gender: "Nam", hobbies: "Love Cats", bio: "Halo")
    return EventsView()
        .environmentObject(eventVM)
        .environmentObject(authVM)
        .environmentObject(GoogleAuthViewModel())
}
