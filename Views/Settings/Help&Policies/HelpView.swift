//
//  HelpView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 27/4/25.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var isSupportExpanded: Bool = false
    @State private var showCopyToast: Bool = false
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Welcome Section
                    welcomeSection
                    
                    // MARK: - Usage Guide Section
                    usageGuideSection
                    
                    // MARK: - Support Contact Section
                    supportContactSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(.all, edges: .horizontal)
            .navigationTitle("Help ⋆˚࿔")
            .navigationBarTitleDisplayMode(.inline)
            
            // Toast for copy confirmation
            if showCopyToast {
                Toast(message: "Bạn đã copy thành công ^^")
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Chào mừng bạn đến với SmartTask ❀")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            Text("FriskChara ở đây để giúp bạn! 𓆩❤︎𓆪")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            Text("SmartTask giúp bạn quản lý công việc, sự kiện và sức khỏe một cách vui vẻ. Nếu gặp khó khăn, hãy xem các câu hỏi dưới đây hoặc liên hệ mình!")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [themeColor.opacity(0.15), Color(UIColor.systemBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(30)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Usage Guide Section
    private var usageGuideSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Hướng dẫn sử dụng ✦")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            
            // Thêm Task mới
            guideItem(
                icon: "leaf.circle.fill",
                color: .blue,
                title: "Thêm task mới",
                description: "Vào màn hình chính, nhấn nút hình tròn chiếc lá 'leaf', để điền thông tin task."
            )

            // Thay đổi Theme
            guideItem(
                icon: "paintpalette.fill",
                color: .purple,
                title: "Thay đổi theme",
                description: "Vào 'Cài đặt' > 'Theme' để chọn màu sắc yêu thích của bạn."
            )

            // Quản lý Category
            guideItem(
                icon: "folder.fill",
                color: .green,
                title: "Xóa hoặc ẩn Category",
                description: "Ấn biểu tượng pháo hoa (trên hình trái tim) > 'Manage Categories', chọn dấu 3 chấm ngang để Delete hoặc Hide."
            )

            // Reload Trang Chủ
            guideItem(
                icon: "heart.fill",
                color: .pink,
                title: "Làm mới trang chủ",
                description: "Nhấn vào hình trái tim ở trang chủ để reload và cập nhật các nhiệm vụ mới."
            )

            // Hiển thị thông tin Category trong Lịch
            guideItem(
                icon: "calendar.badge.clock",
                color: .orange,
                title: "Xem Category trong Lịch",
                description: "Trong màn hình lịch, các dấu chấm nhỏ là category trong tháng. Ấn đúp vào chỗ có chấm để xem thông tin category chi tiết."
            )

            // Đồng bộ với Google Calendar
            guideItem(
                icon: "arrow.triangle.2.circlepath.circle.fill",
                color: .cyan,
                title: "Kết nối Google Calendar",
                description: "Vào 'Cài đặt', chọn 'Sync with Google Calendar' và đăng nhập tài khoản Google để sử dụng."
            )
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(30)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Support Contact Section
    private var supportContactSection: some View {
        Button(action: {
            isSupportExpanded.toggle()
        }) {
            DisclosureGroup(
                isExpanded: $isSupportExpanded,
                content: {
                    Button(action: {
                        UIPasteboard.general.string = "loi.nguyenbao02@gmail.com"
                        withAnimation {
                            showCopyToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showCopyToast = false
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            
                            Text("Email hỗ trợ: loi.nguyenbao02@gmail.com")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "document.on.document")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(25)
                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                },
                label: {
                    Text("Liên hệ hỗ trợ ⋆˙⟡")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            )
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(30)
            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.5), value: isSupportExpanded)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper: Guide Item
    private func guideItem(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        .frame(minHeight: 100)
    }
}

#Preview {
    NavigationStack {
        HelpView()
            .environment(\.themeColor, .blue)
    }
}
