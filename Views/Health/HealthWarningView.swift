//
//  HealthWarningView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 14/3/25.
//

import SwiftUI
import Charts // Thêm Charts framework để vẽ biểu đồ

struct HealthWarningView: View {
    // MARK: - Environment and State
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.themeColor) var themeColor: Color
    
    @StateObject private var viewModel: HealthWarningViewModel
    
    @State private var isWorkModeMenuExpanded: Bool = false
    @State private var isHealthStatusMenuExpanded: Bool = false
    @State private var isMeasurementMenuExpanded: Bool = false
    
    
    // MARK: - Initialization
    init(authVM: AuthViewModel = AuthViewModel(), taskVM: TaskViewModel = TaskViewModel(notificationsVM: NotificationsViewModel(), userId: nil), eventVM: EventViewModel = EventViewModel()) {
        _viewModel = StateObject(wrappedValue: HealthWarningViewModel(
            taskVM: taskVM,
            eventVM: eventVM,
            userId: authVM.currentUser?.id
        ))
    }
    
    // MARK: - Theme Color Mapping
    private var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [themeColor.opacity(0.8), themeColor]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Helper Views
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemBackground))
            .shadow(color: .primary.opacity(0.1), radius: 3, x: 0, y: 2)
    }
    
    private func weightTextField() -> some View {
        TextField("Cân nặng (kg)", text: $viewModel.weight)
            .keyboardType(.decimalPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .background(textFieldBackground)
    }

    private func heightTextField() -> some View {
        TextField("Chiều cao (cm)", text: $viewModel.height)
            .keyboardType(.decimalPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .background(textFieldBackground)
    }
    
    private func measurementInputSection() -> some View {
        VStack(spacing: 15) {
            weightTextField()
            heightTextField()
            
            Button(action: {
                viewModel.saveUserMeasurements()
            }) {
                Text("Lưu thông tin")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(gradient)
                    .cornerRadius(50)
                    .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
        )
    }
    
    private func bmiDisplaySection() -> some View {
        VStack(spacing: 10) {
            Text("Chỉ số BMI: \(String(format: "%.1f", viewModel.bmi!))")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Text(viewModel.bmiCategory)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(viewModel.bmiColor(for: viewModel.bmi!))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
        )
    }
    
    private func workModeButton(mode: WorkMode, selectedMode: WorkMode, period: String) -> some View {
        Button(action: {
            switch period {
            case "day":
                viewModel.dayMode = mode
            case "week":
                viewModel.weekMode = mode
            case "month":
                viewModel.monthMode = mode
            case "year":
                viewModel.yearMode = mode
            default:
                break
            }
            viewModel.analyzeWorkload()
        }) {
            Text(mode.rawValue)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(selectedMode == mode ? .white : themeColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    selectedMode == mode
                    ? AnyView(gradient)
                    : AnyView(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                )
                .cornerRadius(8)
                .shadow(color: .primary.opacity(selectedMode == mode ? 0.2 : 0), radius: 3, x: 0, y: 2)
        }
    }
    
    private func workModeSelectionSection() -> some View {
        VStack(spacing: 15) {
            Button(action: {
                withAnimation(.easeInOut) {
                    isWorkModeMenuExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Chọn chế độ làm việc ⟢")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                    Image(systemName: isWorkModeMenuExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(themeColor)
                }
            }
            
            // Chế độ theo ngày (luôn hiển thị)
            VStack(spacing: 5) {
                Text("Theo ngày ❀")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                HStack(spacing: 10) {
                    ForEach(WorkMode.allCases, id: \.rawValue) { mode in
                        workModeButton(mode: mode, selectedMode: viewModel.dayMode, period: "day")
                    }
                }
            }
            
            // Các chế độ khác (hiển thị khi mở menu)
            if isWorkModeMenuExpanded {
                // Chế độ theo tuần
                VStack(spacing: 5) {
                    Text("Theo tuần ☀︎")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                    HStack(spacing: 10) {
                        ForEach(WorkMode.allCases, id: \.rawValue) { mode in
                            workModeButton(mode: mode, selectedMode: viewModel.weekMode, period: "week")
                        }
                    }
                }
                
                // Chế độ theo tháng
                VStack(spacing: 5) {
                    Text("Theo tháng ༄.ೃ࿔")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                    HStack(spacing: 10) {
                        ForEach(WorkMode.allCases, id: \.rawValue) { mode in
                            workModeButton(mode: mode, selectedMode: viewModel.monthMode, period: "month")
                        }
                    }
                }
                
                // Chế độ theo năm
                VStack(spacing: 5) {
                    Text("Theo năm ❄︎")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                    HStack(spacing: 10) {
                        ForEach(WorkMode.allCases, id: \.rawValue) { mode in
                            workModeButton(mode: mode, selectedMode: viewModel.yearMode, period: "year")
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(.systemBackground))
                .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
        )
    }
    
    private func healthStatusSection() -> some View {
        VStack(spacing: 15) {
            Button(action: {
                withAnimation(.easeInOut) {
                    isHealthStatusMenuExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Trạng thái sức khỏe lịch làm việc")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                    Image(systemName: isHealthStatusMenuExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(themeColor)
                }
            }
            
            // Theo ngày (luôn hiển thị)
            VStack(spacing: 5) {
                Text("Theo ngày 🌸")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                Text(viewModel.dayStatus)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(viewModel.dayColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.dayColor.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(themeColor.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            
            // Các trạng thái khác (hiển thị khi mở menu)
            if isHealthStatusMenuExpanded {
                // Theo tuần
                VStack(spacing: 5) {
                    Text("Theo tuần ☀️")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(viewModel.weekStatus)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.weekColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.weekColor.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(themeColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                // Theo tháng
                VStack(spacing: 5) {
                    Text("Theo tháng 🍁")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(viewModel.monthStatus)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(viewModel.monthColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.monthColor.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(themeColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                // Theo năm
                VStack(spacing: 5) {
                    Text("Theo năm ❄️")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(viewModel.yearStatus)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.yearColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.yearColor.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(themeColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                // Tổng hợp
                VStack(spacing: 5) {
                    Text("Tổng hợp ʚଓ")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(viewModel.overallStatus)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.overallColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.overallColor.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(themeColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
        )
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Phần nhập cân nặng và chiều cao và BMI
                    VStack(spacing: 15) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isMeasurementMenuExpanded.toggle()
                            }
                        }) {
                            Text("❤︎ Thông tin sức khỏe ↓ ")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                        }
                        
                        if isMeasurementMenuExpanded {
                            measurementInputSection()
                            if viewModel.bmi != nil {
                                bmiDisplaySection()
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
                    )
                    
                    // Phần chọn chế độ làm việc
                    workModeSelectionSection()
                    
                    // Phần hiển thị trạng thái sức khỏe lịch làm việc
                    healthStatusSection()
                    
                    // Phần biểu đồ Tasks và Events
                    VStack(spacing: 20) {
                        BarChartsView(taskVM: taskVM, eventVM: eventVM)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
                            )
                        
                        PieChartsView(taskVM: taskVM, eventVM: eventVM)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
                            )
                    }
                }
                .padding()
            }
            .navigationTitle("Trạng thái sức khỏe ✦")
            .onAppear {
                if authVM.currentUser?.id != nil {
                    taskVM.userId = authVM.currentUser?.id
                    viewModel.fetchUserHealth {
                        viewModel.analyzeWorkload()
                    }
                }
            }
        }
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
    let eventVM = EventViewModel()
    let authVM = AuthViewModel()
    authVM.currentUser = UserModel(id: 7, name: "Tester01", email: "Test01", password: "123", avatarURL: nil, description: "I’m still newbie.", dateOfBirth: Date(), location: "Cat Islands", joinedDate: nil, gender: "Nam", hobbies: "Love Cats", bio: "Halo")
    authVM.isAuthenticated = true
    
    return NavigationStack {
        HealthWarningView(authVM: authVM, taskVM: taskVM, eventVM: eventVM)
            .environmentObject(authVM)
            .environmentObject(taskVM)
            .environmentObject(eventVM)
            .environment(\.themeColor, .blue)
    }
}
