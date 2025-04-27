//
//  FAQView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 27/4/25.
//

import SwiftUI

struct FAQView: View {
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var expandedFAQ: Int? = nil
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // MARK: - Header
                headerSection
                
                // MARK: - FAQ List
                faqListSection
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
        .navigationTitle("FAQ ⓘ")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Câu Hỏi Thường Gặp ✦")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            Text("Tìm câu trả lời cho các thắc mắc của bạn về SmartTask! ❅")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(minHeight: 120) // Chuẩn hóa chiều cao
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
    
    // MARK: - FAQ List Section
    private var faqListSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Danh sách FAQ ⟢")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            
            // FAQ 1
            faqItem(
                id: 1,
                question: "Làm sao để thêm task mới?",
                answer: "Bạn vào màn hình chính, nhấn nút có hình chiếc lá 'leaf' và điền thông tin task."
            )
            
            // FAQ 2
            faqItem(
                id: 2,
                question: "Theme có thể thay đổi ở đâu?",
                answer: "Vào Settings > Theme để chọn màu yêu thích!"
            )
            
            // FAQ 3
            faqItem(
                id: 3,
                question: "Làm sao để xóa hoặc ẩn category?",
                answer: "Ấn hình pháo hoa (Ở trên hình Trái tim) > Manage Categories, chọn dấu 3 chấm ngang và nhấn Delete hoặc Hide."
            )
            
            // FAQ 4
            faqItem(
                id: 4,
                question: "Hình trái tim ở trang chủ là sao thế?",
                answer: "Hình trái tim là để tải lại trang chủ."
            )
            
            // FAQ 5
            faqItem(
                id: 5,
                question: "Mấy dấu chấm nho nhỏ đầy đủ màu sắc ở Lịch SmartTask là gì thế?",
                answer: "Đó là dấu chấm thể Task của bạn trong tháng. Ngoài ra bạn được ấn đúp vào chỗ 2 chấm đó là sẽ hiện ra thông tin về category của bạn."
            )
            
            // FAQ 6
            faqItem(
                id: 6,
                question: "Tại sao mình lại không ấn vào được Lịch Google Calendar?",
                answer: "Bạn cần Login tài khoản trước. Vào Setting ấn chọn 'Sync with Google Calendar'"
            )
        }
        .padding()
        .frame(minHeight: 200) // Chuẩn hóa chiều cao
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
    
    // MARK: - Helper: FAQ Item
    private func faqItem(id: Int, question: String, answer: String) -> some View {
        VStack {
            HStack {
                Text(question)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: expandedFAQ == id ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(UIColor.systemBackground).opacity(0.95))
            .cornerRadius(25)
            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut) {
                    expandedFAQ = expandedFAQ == id ? nil : id
                }
            }
            
            if expandedFAQ == id {
                Text(answer)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .cornerRadius(25)
                    .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FAQView()
            .environment(\.themeColor, .blue)
    }
}
