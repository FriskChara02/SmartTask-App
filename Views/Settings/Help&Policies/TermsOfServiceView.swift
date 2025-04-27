//
//  TermsOfServiceView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 27/4/25.
//

import SwiftUI

struct TermsOfServiceView: View {
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
                    
                    // MARK: - Rights and Responsibilities Section
                    rightsAndResponsibilitiesSection
                    
                    // MARK: - Usage Policy Section
                    usagePolicySection
                    
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
            .navigationTitle("Terms of Service 📜")
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
            Text("Điều khoản dịch vụ ❀")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            Text("Chào bạn đến với SmartTask! ❤︎")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            Text("Bằng cách sử dụng SmartTask, bạn đồng ý với các điều khoản dưới đây. Hãy đọc kỹ nhé!")
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
    
    // MARK: - Rights and Responsibilities Section
    private var rightsAndResponsibilitiesSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Quyền và Trách nhiệm ✦")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            
            // Quyền của bạn
            termItem(
                icon: "person.circle.fill",
                color: .blue,
                title: "Quyền của bạn",
                description: "Bạn có quyền sử dụng SmartTask để quản lý công việc, sự kiện và tùy chỉnh theme."
            )
            
            // Trách nhiệm của bạn
            termItem(
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                title: "Trách nhiệm của bạn",
                description: "Không sử dụng SmartTask cho mục đích bất hợp pháp hoặc làm ảnh hưởng đến người khác."
            )
            
            // Không gian tích cực
            termItem(
                icon: "hands.sparkles.fill",
                color: .green,
                title: "Không gian tích cực",
                description: "SmartTask đề cao sự cởi mở, thân thiện. Hãy tôn trọng và hỗ trợ nhau để xây dựng một cộng đồng ấm áp."
            )
            
            // Thể hiện sự tử tế
            termItem(
                icon: "heart.fill",
                color: .pink,
                title: "Thể hiện sự tử tế",
                description: "Đối xử với mọi người như cách bạn muốn được đối xử. Hãy xây dựng, lắng nghe, và lan tỏa năng lượng tích cực."
            )
            
            // Những điều không được chấp nhận
            termItem(
                icon: "nosign",
                color: .red,
                title: "Những điều KHÔNG được chấp nhận",
                description: "Spam, troll, phá hoại, quảng cáo trái phép, nội dung độc hại, gây rối, xúc phạm, phân biệt vùng miền... sẽ bị xử lý nghiêm."
            )
            
            // Voice Chat và không gian riêng tư
            termItem(
                icon: "mic.fill",
                color: .purple,
                title: "Voice Chat & Không gian riêng",
                description: "Tôn trọng phòng voice, tránh spam, không gây khó chịu. Chủ phòng có quyền kick nếu cần thiết."
            )
            
            // Lưu ý quan trọng
            termItem(
                icon: "lightbulb.fill",
                color: .yellow,
                title: "Lưu ý",
                description: "Vi phạm sẽ bị xử lý tùy mức độ. Các quy tắc có thể cập nhật bất kỳ lúc nào. Tuân thủ Điều khoản & Nguyên tắc cộng đồng SmartTask."
            )
            
            // Thông điệp cuối cùng
            termItem(
                icon: "leaf.fill",
                color: .mint,
                title: "Thông điệp từ SmartTask",
                description: "🌿 SmartTask không phải Tinder! Hãy gieo mầm trách nhiệm và yêu thương cùng nhau nhé!"
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
    
    // MARK: - Usage Policy Section
    private var usagePolicySection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Chính sách sử dụng ⋆˙⟡")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            
            // Bảo vệ tài khoản
            termItem(
                icon: "lock.shield.fill",
                color: .green,
                title: "Bảo vệ tài khoản",
                description: "Bạn chịu trách nhiệm bảo mật thông tin đăng nhập của mình."
            )
            
            // Cập nhật dịch vụ
            termItem(
                icon: "arrow.triangle.2.circlepath",
                color: .purple,
                title: "Cập nhật dịch vụ",
                description: "SmartTask có quyền cập nhật hoặc thay đổi dịch vụ mà không cần thông báo trước."
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
                    Text("Liên hệ về điều khoản ᝰ.ᐟ")
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
    
    // MARK: - Helper: Term Item
    private func termItem(icon: String, color: Color, title: String, description: String) -> some View {
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
        TermsOfServiceView()
            .environment(\.themeColor, .blue)
    }
}
