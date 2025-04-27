//
//  ShareAppView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 27/4/25.
//

import SwiftUI

struct ShareAppView: View {
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Placeholder
                    placeholderSection
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
            .navigationTitle("Share App ♡ㅤ ⎙ㅤ ⌲")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Chia Sẻ SmartTask ❀")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            Text("Hãy chia sẻ ứng dụng với bạn bè của bạn! ❤︎")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(minHeight: 100) // Chuẩn hóa chiều cao
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
    
    // MARK: - Placeholder Section
    private var placeholderSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 40))
                .foregroundColor(themeColor)
            
            Text("Tính năng chia sẻ sắp ra mắt! 🌟")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            Text("Mnh đang làm việc để bạn có thể chia sẻ SmartTask với bạn bè. Hãy quay lại sớm nhé!")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(minHeight: 100) // Chuẩn hóa chiều cao
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
}

#Preview {
    NavigationStack {
        ShareAppView()
            .environment(\.themeColor, .blue)
    }
}
