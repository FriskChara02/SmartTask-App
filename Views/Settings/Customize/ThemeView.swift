import SwiftUI
import PhotosUI

struct ThemeView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false // @AppStorage để lưu lâu dài
    @AppStorage("themeColor") private var themeColor: String = ""
    @AppStorage("themeTexture") private var themeTexture: String = ""
    @AppStorage("themeScenery") private var themeScenery: String = ""
    @AppStorage("customPhotoData") private var customPhotoData: Data?
    @Environment(\.themeColor) var selectedThemeColor
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    let colors: [(name: String, color: Color)] = [
        ("Default", .gray), // Thêm Default với màu gray (thay đổi màu mặc định)
        ("Blue", .blue),
        ("Green", .green),
        ("Pink", .pink),
        ("Purple", .purple),
        ("Red", .red),
        ("Black", .black),
        ("Yellow", .yellow),
        ("Orange", .orange),
        ("Mint", .mint),
        ("Teal", .teal),
        ("Cyan", .cyan),
        ("Indigo", .indigo),
        ("Brown", .brown),
        ("White", .white)
    ]
    
    // Danh sách Texture (Gradient)
    let textures: [(name: String, gradient: Gradient?)] = [
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
    
    // Danh sách Scenery (Assets)
    let sceneries: [(name: String, imageName: String?)] = [
        ("Default", nil),
        ("Tekapo Lake", "Tekapo Lake"),
        ("Meadow", "meadow-with-trees-wooden-fence"),
        ("Wet Vietnam", "wet-vietnam-mountain-flow-stream-rural"),
        ("Cascade", "cascade-boat-clean-china-natural-rural"),
        ("Fuji", "fuji-mountain-kawaguchiko-lake-sunset-autumn-seasons-fuji-mountain-yamanachi-japan")
    ]
    
    var body: some View {
        NavigationView {
            List {
                // Darkmode
                Section(header: Text("Appearance ⟢").font(.headline)) {
                    Toggle(isOn: $isDarkMode) {
                        Text("Dark Mode ⋆˚࿔").font(.body)
                    }
                }
                
                // Pure Color
                Section(header: Text("Pure Color ⋆˙⟡").font(.headline)) {
                    ForEach(colors, id: \.name) { color in
                        HStack {
                            if color.name == "Default" {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            } else {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 20, height: 20)
                            }
                            Text(color.name)
                            Spacer()
                            if themeColor == color.name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            themeColor = color.name
                            print("DEBUG: Selected color: \(color.name)")
                        }
                    }
                }
                
                // Texture
                Section(header: Text("Texture ✧").font(.headline)) {
                    ForEach(textures, id: \.name) { texture in
                        HStack {
                            if texture.name == "Default" {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            } else {
                                Circle()
                                    .fill(LinearGradient(gradient: texture.gradient ?? Gradient(colors: [.gray]), startPoint: .top, endPoint: .bottom))
                                    .frame(width: 20, height: 20)
                            }
                            Text(texture.name)
                            Spacer()
                            if themeTexture == texture.name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            themeTexture = texture.name
                            themeScenery = ""
                            customPhotoData = nil
                            print("DEBUG: Selected texture: \(texture.name)")
                        }
                    }
                }
                
                // Scenery
                Section(header: Text("Scenery ✦").font(.headline)) {
                    ForEach(sceneries, id: \.name) { scenery in
                        HStack {
                            if scenery.name == "Default" {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            } else {
                                Image(scenery.imageName ?? "circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                            Text(scenery.name)
                            Spacer()
                            if themeScenery == scenery.name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            themeScenery = scenery.name
                            themeTexture = ""
                            customPhotoData = nil
                            print("DEBUG: Selected scenery: \(scenery.name)")
                        }
                    }
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "sparkles")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.gray)
                            Text("Your Photos")
                            Spacer()
                            if themeScenery == "Your Photos" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let item = newItem {
                                do {
                                    if let data = try await item.loadTransferable(type: Data.self) {
                                        if let uiImage = UIImage(data: data), let compressedData = uiImage.jpegData(compressionQuality: 0.5) {
                                            customPhotoData = compressedData
                                            themeScenery = "Your Photos"
                                            themeTexture = ""
                                            print("DEBUG: Selected custom photo, compressed data size: \(compressedData.count) bytes")
                                        } else {
                                            print("DEBUG: Failed to compress photo")
                                        }
                                    }
                                } catch {
                                    print("DEBUG: Error loading photo: \(error)")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Theme ❀")
            .background(backgroundView().opacity(0.5))
        }
        .onChange(of: themeColor) { _, newValue in
            print("DEBUG: Theme color changed to: \(newValue)")
        }
        .onChange(of: themeTexture) { _, newValue in
            print("DEBUG: Theme texture changed to: \(newValue)")
        }
        .onChange(of: themeScenery) { _, newValue in
            print("DEBUG: Theme scenery changed to: \(newValue)")
        }
    }
    
    private func backgroundView() -> some View {
        if !themeTexture.isEmpty && themeTexture != "Default" {
            if let selectedGradient = textures.first(where: { $0.name == themeTexture })?.gradient {
                return AnyView(LinearGradient(gradient: selectedGradient, startPoint: .top, endPoint: .bottom))
            }
        } else if !themeScenery.isEmpty && themeScenery != "Default" {
            if themeScenery == "Your Photos", let photoData = customPhotoData, let uiImage = UIImage(data: photoData) {
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
        return AnyView(Color.gray)
    }
}

#Preview {
    NavigationStack {
        ThemeView()
            .environment(\.themeColor, .blue)
    }
}
