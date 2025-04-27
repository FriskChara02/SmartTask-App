//
//  PrivacyPolicyView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 27/4/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var isContactExpanded: Bool = false
    @State private var showCopyToast: Bool = false
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Introduction Section
                    introductionSection
                    
                    // MARK: - Data Collection Section
                    dataCollectionSection
                    
                    // MARK: - Data Usage Section
                    dataUsageSection
                    
                    // MARK: - Contact Section
                    contactSection
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
            .navigationTitle("Privacy Policy 🔐")
            .navigationBarTitleDisplayMode(.inline)
            
            // Toast for copy confirmation
            if showCopyToast {
                Toast(message: "Bạn đã copy thành công ^^")
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
    
    // MARK: - Introduction Section
    private var introductionSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Chính sách bảo mật ⚚")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            Text("Mình tôn trọng quyền riêng tư của bạn! 𖤝")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            Text("Chính sách của mình giải thích cách SmartTask thu thập, sử dụng và bảo vệ thông tin của bạn. 🔒")
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
    
    // MARK: - Data Collection Section
    private var dataCollectionSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Thông tin chúng mình thu thập ✦")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            
            // Thông tin cá nhân
            dataItem(
                icon: "person.fill",
                color: .blue,
                title: "Thông tin cá nhân",
                description: "Tên, email và ảnh đại diện bạn cung cấp khi đăng ký."
            )
            
            // Dữ liệu task và category
            dataItem(
                icon: "list.bullet",
                color: .green,
                title: "Dữ liệu task, sự kiện và category",
                description: "Task, sự kiện, category và thông tin liên quan để quản lý công việc."
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
    
    // MARK: - Data Usage Section
    private var dataUsageSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Cách sử dụng và chia sẻ ⋆˙⟡")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            
            // Bảo mật dữ liệu
            dataItem(
                icon: "lock.fill",
                color: .purple,
                title: "Bảo mật dữ liệu",
                description: "Mình không chia sẻ dữ liệu cá nhân với bên thứ ba, trừ khi có sự đồng ý của bạn."
            )
            
            // Dịch vụ đám mây
            dataItem(
                icon: "cloud.fill",
                color: .orange,
                title: "Dịch vụ đám mây",
                description: "Dữ liệu được lưu trữ an toàn trên máy chủ để đồng bộ Google Calendar (nếu bật)."
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
    
    // MARK: - Contact Section
    private var contactSection: some View {
        Button(action: {
            isContactExpanded.toggle()
        }) {
            DisclosureGroup(
                isExpanded: $isContactExpanded,
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
                                .foregroundColor(.teal)
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
                    Text("Liên hệ về bảo mật ᝰ.ᐟ")
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
            .animation(.easeInOut(duration: 0.5), value: isContactExpanded)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper: Data Item
    private func dataItem(icon: String, color: Color, title: String, description: String) -> some View {
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
        .cornerRadius(30)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        .frame(minHeight: 100)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
            .environment(\.themeColor, .blue)
    }
}
