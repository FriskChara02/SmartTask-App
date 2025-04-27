//
//  SendFeedbackView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 27/4/25.
//

import SwiftUI

struct SendFeedbackView: View {
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var feedback: String = ""
    @State private var showCopyToast: Bool = false
    @State private var showSuccessToast: Bool = false
    @State private var showErrorToast: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Feedback Input
                    feedbackInputSection
                    
                    // MARK: - Contact Info
                    contactInfoSection
                    
                    // MARK: - Submit Button
                    submitButton
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
            .navigationTitle("Send Feedback 📩")
            .navigationBarTitleDisplayMode(.inline)
            
            // Toasts
            if showCopyToast {
                Toast(message: "Bạn đã copy thành công ^^")
                    .transition(.opacity)
                    .zIndex(1)
            }
            if showSuccessToast {
                Toast(message: "Feedback đã được gửi! Cảm ơn bạn! (づ ᴗ _ᴗ)づ♡")
                    .transition(.opacity)
                    .zIndex(1)
            }
            if showErrorToast {
                Toast(message: errorMessage)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Gửi Feedback ❆")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            Text("Ý kiến của bạn giúp SmartTask ngày càng tốt hơn! 𓆩❤︎𓆪")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(minHeight: 100)
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
    
    // MARK: - Feedback Input Section
    private var feedbackInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nội dung Feedback ✦")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            Text("Kèm theo Gmail của bạn để mình phản hồi nhé! ⟢")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            TextEditor(text: $feedback)
                .frame(minHeight: 150)
                .padding()
                .background(Color(UIColor.systemBackground).opacity(0.95))
                .cornerRadius(25)
                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(themeColor.opacity(0.3), lineWidth: 1)
                )
        }
        .padding()
        .frame(minHeight: 300)
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
    
    // MARK: - Contact Info Section
    private var contactInfoSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Liên hệ với mình ⋆˙⟡")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            
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
                        .font(.system(size: 15, weight: .medium, design: .rounded))
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
        }
        .padding()
        .frame(minHeight: 100)
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
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            guard let userId = authViewModel.currentUser?.id else {
                errorMessage = "Bạn cần đăng nhập để gửi feedback ⟡"
                withAnimation {
                    showErrorToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showErrorToast = false
                    }
                }
                return
            }
            
            if !feedback.isEmpty {
                APIService.saveFeedback(userId: userId, feedback: feedback) { success, message in
                    if success {
                        withAnimation {
                            showSuccessToast = true
                        }
                        feedback = ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSuccessToast = false
                            }
                        }
                    } else {
                        errorMessage = message
                        withAnimation {
                            showErrorToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showErrorToast = false
                            }
                        }
                    }
                }
            }
        }) {
            Text("Gửi Feedback ⟢")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(themeColor)
                .cornerRadius(25)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .disabled(feedback.isEmpty)
        .opacity(feedback.isEmpty ? 0.6 : 1.0)
    }
}

#Preview {
    NavigationStack {
        SendFeedbackView()
            .environment(\.themeColor, .blue)
            .environmentObject(AuthViewModel())
    }
}
