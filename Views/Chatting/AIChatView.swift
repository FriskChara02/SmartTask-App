//
//  AIChatView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 4/5/25.
//

import SwiftUI

struct AIChatView: View {
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var showComingSoon: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeColor.opacity(0.1),
                        Color(UIColor.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(themeColor)
                            .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Text("Chức năng Chat với AI chưa được triển khai")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showComingSoon.toggle()
                            }
                        }) {
                            Text(showComingSoon ? "Khám phá sau" : "Quay lại")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .scaleEffect(showComingSoon ? 1.0 : 1.1)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor.systemFill),
                                Color(UIColor.systemBackground)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .transition(.scale)
                    
                    Spacer()
                }
            }
            .navigationTitle("Chat AI")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AIChatView()
        .environment(\.themeColor, .cyan)
}
