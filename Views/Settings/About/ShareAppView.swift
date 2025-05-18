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
    @AppStorage("themeColor") private var themeColorStorage: String = ""
    @AppStorage("themeTexture") private var themeTexture: String = ""
    @AppStorage("themeScenery") private var themeScenery: String = ""
    @AppStorage("customPhotoData") private var customPhotoData: Data?
    
    private let colors: [(name: String, color: Color)] = [
        ("Default", .gray), ("Blue", .blue), ("Green", .green), ("Pink", .pink),
        ("Purple", .purple), ("Red", .red), ("Black", .black), ("Yellow", .yellow),
        ("Orange", .orange), ("Mint", .mint), ("Teal", .teal), ("Cyan", .cyan),
        ("Indigo", .indigo), ("Brown", .brown), ("White", .white)
    ]
    
    private let textures: [(name: String, gradient: Gradient?)] = [
        ("Default", nil),
        ("Sunset Gradient", Gradient(colors: [.orange, .pink, .purple])),
        ("Ocean Gradient", Gradient(colors: [.blue, .cyan, .teal])),
        ("Forest Gradient", Gradient(colors: [.green, .mint, .brown])),
        ("Twilight Glow", Gradient(colors: [.purple, .indigo, .blue])),
        ("Desert Heat", Gradient(colors: [.red, .orange, .yellow])),
        ("Aurora", Gradient(colors: [.cyan, .green, .blue])),
        ("Candy Pop", Gradient(colors: [.pink, .cyan, .yellow])),
        ("Midnight", Gradient(colors: [.black, .indigo, .gray])),
        ("Spring Bloom", Gradient(colors: [.mint, .pink, .white])),
        ("Golden Hour", Gradient(colors: [.yellow, .orange, .red])),
        ("Frost", Gradient(colors: [.white, .cyan, .blue]))
    ]
    
    private let sceneries: [(name: String, imageName: String?)] = [
        ("Default", nil),
        ("Tekapo Lake", "Tekapo Lake"),
        ("Meadow", "meadow-with-trees-wooden-fence"),
        ("Wet Vietnam", "wet-vietnam-mountain-flow-stream-rural"),
        ("Cascade", "cascade-boat-clean-china-natural-rural"),
        ("Fuji", "fuji-mountain-kawaguchiko-lake-sunset-autumn-seasons-fuji-mountain-yamanachi-japan")
    ]
    
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
                backgroundView()
                    .opacity(0.5)
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
        .frame(minHeight: 100)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    (colors.first(where: { $0.name == themeColorStorage })?.color ?? .gray).opacity(0.15),
                    Color(UIColor.systemBackground)
                ]),
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
                .foregroundColor(colors.first(where: { $0.name == themeColorStorage })?.color ?? .gray)
            
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
        .frame(minHeight: 100)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    (colors.first(where: { $0.name == themeColorStorage })?.color ?? .gray).opacity(0.1),
                    Color(UIColor.systemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(30)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Background View
    private func backgroundView() -> some View {
        if !themeTexture.isEmpty && themeTexture != "Default" {
            if let selectedGradient = textures.first(where: { $0.name == themeTexture })?.gradient {
                return AnyView(LinearGradient(
                    gradient: selectedGradient,
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
        } else if !themeScenery.isEmpty && themeScenery != "Default" {
            if themeScenery == "Your Photos", let photoData = UserDefaults.standard.data(forKey: "customPhotoData"), let uiImage = UIImage(data: photoData) {
                return AnyView(Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipped())
            } else if let selectedImage = sceneries.first(where: { $0.name == themeScenery })?.imageName {
                return AnyView(Image(selectedImage)
                    .resizable()
                    .scaledToFill()
                    .clipped())
            }
        }
        return AnyView(LinearGradient(
            gradient: Gradient(colors: [
                (colors.first(where: { $0.name == themeColorStorage })?.color ?? .gray).opacity(0.1),
                Color(UIColor.systemBackground)
            ]),
            startPoint: .top,
            endPoint: .bottom
        ))
    }
}

#Preview {
    NavigationStack {
        ShareAppView()
            .environment(\.themeColor, .blue)
    }
}
