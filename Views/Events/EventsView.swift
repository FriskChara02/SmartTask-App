import SwiftUI

struct EventsView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.themeColor) var themeColor
    
    @State private var showingAddEvent = false
    @State private var selectedEvent: EventModel?
    @State private var showConflictAlert = false
    @State private var showYourEvents = true
    @State private var showSpecialEvents = true
    @State private var showCompletedEvents = true
    
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Your Events
                        DisclosureGroup(isExpanded: $showYourEvents) {
                            ForEach(eventVM.events) { event in
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
                            ForEach(specialEvents) { event in
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
                            ForEach(eventVM.completedEvents) { event in
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
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
                    .environmentObject(eventVM)
            }
            .onAppear {
                eventVM.fetchEvents(forUserId: 1)
            }
            .alert(isPresented: $showConflictAlert) {
                Alert(
                    title: Text("Xung đột lịch"),
                    message: Text(eventVM.conflictMessage ?? "Có lỗi xảy ra"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: eventVM.conflictMessage) { _, newValue in
                showConflictAlert = newValue != nil
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
    
    // Helper để tạo ngày lễ
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

// MARK: - Add Event View
struct AddEventView: View {
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColor) var themeColor
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date?
    @State private var priority = "Medium"
    @State private var isAllDay = false
    
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
                        let newEvent = EventModel(
                            id: Int.random(in: 1000...9999),
                            userId: 1,
                            title: title,
                            description: description.isEmpty ? nil : description,
                            startDate: startDate,
                            endDate: endDate,
                            priority: priority,
                            isAllDay: isAllDay,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        withAnimation(.spring()) {
                            eventVM.addEvent(event: newEvent)
                        }
                    }) {
                        Text("Lưu ❀")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(20)
                            .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    .disabled(title.isEmpty)
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
    EventsView()
        .environmentObject(EventViewModel())
}
