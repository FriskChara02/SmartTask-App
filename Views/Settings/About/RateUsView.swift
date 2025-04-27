//
//  RateUsView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 27/4/25.
//

import SwiftUI

struct RateUsView: View {
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var showSuccessToast: Bool = false
    @State private var showErrorToast: Bool = false
    @State private var errorMessage: String = ""
    @State private var ratings: [RatingModel] = []
    @State private var currentGroup: Int = 0
    @State private var isDragging: Bool = false // Trạng thái kéo ngang
    @State private var selectedRatingId: Int? = nil
    @State private var animationStartTime: Date? // Thời gian bắt đầu animation
    
    private let groupSize = 5
    private let animationDuration: Double = 15.0 // Thời gian cho 5 đánh giá
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Ratings List
                    ratingsListSection
                    
                    // MARK: - Rating Input
                    ratingInputSection
                    
                    // MARK: - Username Display
                    usernameDisplaySection
                    
                    // MARK: - Comment Input
                    commentInputSection
                    
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
            .navigationTitle("Rate Us ⭑")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchRatings()
                animationStartTime = Date() // Bắt đầu animation
            }
            
            // Toast
            if showSuccessToast {
                Toast(message: "Cảm ơn bạn đã đánh giá! (˶˃⤙˂˶)")
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
            Text("Đánh Giá SmartTask ✦")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            Text("Hãy cho mình biết cảm nhận của bạn! 🌟")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(minHeight: 120) // Chiều cao
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
    
    // MARK: - Rating Input Section
    private var ratingInputSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Đánh Giá ✮")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: rating >= star ? "star.fill" : "star")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                rating = star
                            }
                        }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(UIColor.systemBackground).opacity(0.95))
            .cornerRadius(35)
            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .padding()
        .frame(minHeight: 100) // Chiều cao
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
    
    // MARK: - Username Display Section
    private var usernameDisplaySection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Tên của bạn ⟢")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            
            Text(authViewModel.currentUser?.name ?? "Chưa đăng nhập")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.systemBackground).opacity(0.95))
                .cornerRadius(35)
                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 35)
                        .stroke(themeColor.opacity(0.3), lineWidth: 1)
                )
        }
        .padding()
        .frame(minHeight: 100) // Chiều cao
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
    
    // MARK: - Comment Input Section
    private var commentInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bình luận (tuỳ chọn) ⋆˙⟡")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
            
            TextEditor(text: $comment)
                .frame(minHeight: 100)
                .padding()
                .background(Color(UIColor.systemBackground).opacity(0.95))
                .cornerRadius(15)
                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
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
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            guard let userId = authViewModel.currentUser?.id else {
                errorMessage = "Bạn cần đăng nhập để gửi đánh giá ⭑.ᐟ"
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
            
            if rating > 0 {
                APIService.saveRating(userId: userId, rating: rating, comment: comment.isEmpty ? nil : comment) { success, message in
                    if success {
                        withAnimation {
                            showSuccessToast = true
                        }
                        rating = 0
                        comment = ""
                        fetchRatings()
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
            Text("Gửi Đánh Giá ✰")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(themeColor)
                .cornerRadius(25)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .disabled(rating == 0)
        .opacity(rating == 0 ? 0.6 : 1.0)
    }
    
    // MARK: - Ratings List Section
    private var ratingsListSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Đánh giá từ người dùng ⟡")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            
            if ratings.isEmpty {
                Text("Chưa có đánh giá nào. Hãy là người đầu tiên! 🌟")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
            } else {
                GeometryReader { geometry in
                    TimelineView(.animation(minimumInterval: 1/120, paused: selectedRatingId != nil || isDragging)) { context in
                        let timeElapsed = animationStartTime != nil ? context.date.timeIntervalSince(animationStartTime!) : 0
                        let totalWidth = geometry.size.width * 0.8 * CGFloat(groupSize) + 16 * CGFloat(groupSize - 1) // Tổng chiều rộng 5 đánh giá + khoảng cách
                        let progress = timeElapsed.truncatingRemainder(dividingBy: animationDuration) / animationDuration
                        let offset = totalWidth * CGFloat(progress) - totalWidth
                        let opacity = progress > 0.8 ? 1.0 - (progress - 0.8) / 0.2 : 1.0 // Mờ dần từ 80% đến 100%
                        
                        HStack(spacing: 16) {
                            ForEach(currentRatings) { rating in
                                ratingView(for: rating)
                                    .frame(width: geometry.size.width * 0.8)
                                    .scaleEffect(selectedRatingId == rating.id ? 1.1 : 1.0)
                                    .animation(.easeInOut, value: selectedRatingId)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedRatingId = rating.id
                                        }
                                    }
                                    .onLongPressGesture(minimumDuration: 0, pressing: { isPressing in
                                        if !isPressing {
                                            withAnimation {
                                                selectedRatingId = nil
                                                if !isDragging {
                                                    animationStartTime = context.date
                                                }
                                            }
                                        }
                                    }) { }
                            }
                        }
                        .offset(x: offset)
                        .opacity(opacity)
                        .animation(.easeInOut, value: opacity)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    animationStartTime = nil
                                }
                                .onEnded { value in
                                    isDragging = false
                                    if selectedRatingId == nil {
                                        animationStartTime = context.date
                                    }
                                }
                        )
                        .onChange(of: timeElapsed) { oldValue, newValue in
                            if newValue >= animationDuration {
                                currentGroup = (currentGroup + 1) % (ratings.count / groupSize + (ratings.count % groupSize == 0 ? 0 : 1))
                                animationStartTime = context.date
                            }
                        }
                    }
                }
                .frame(height: 100)
                .clipped()
            }
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
    
    // MARK: - Helper: Rating View
    private func ratingView(for rating: RatingModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rating.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: rating.rating >= star ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            if let comment = rating.comment, !comment.isEmpty {
                Text(comment)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Text("Đánh giá vào: \(rating.createdAt, format: .dateTime.day().month().year())")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper: Current Ratings
    private var currentRatings: [RatingModel] {
        let startIndex = currentGroup * groupSize
        let endIndex = min(startIndex + groupSize, ratings.count)
        return Array(ratings[startIndex..<endIndex])
    }
    
    // MARK: - Helper: Start Animation
    private func startAnimation() {
        animationStartTime = Date()
    }
    
    // MARK: - Helper: Fetch Ratings
    private func fetchRatings() {
        APIService.fetchRatings { success, ratings, error in
            if success, let ratings = ratings {
                print("✅ RateUsView: Loaded \(ratings.count) ratings")
                self.ratings = ratings
                currentGroup = 0
                animationStartTime = Date()
            } else {
                print("❌ RateUsView: Failed to load ratings - Error: \(error ?? "Unknown")")
                self.ratings = []
                errorMessage = error ?? "Không thể tải đánh giá"
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
}

// MARK: - Rating Model
struct RatingModel: Identifiable, Codable {
    let id: Int
    let userId: Int
    let name: String
    let rating: Int
    let comment: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case rating
        case comment
        case createdAt = "created_at"
    }
}

#Preview {
    NavigationStack {
        RateUsView()
            .environment(\.themeColor, .blue)
            .environmentObject(AuthViewModel())
    }
}
