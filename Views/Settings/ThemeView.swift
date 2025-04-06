import SwiftUI

struct ThemeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isDarkMode: Bool = false
    @AppStorage("themeColor") private var themeColor: String = "Blue" //Lưu tên màu mặc định
    @Environment(\.themeColor) var selectedThemeColor
    
    let colors: [(name: String, color: Color)] = [
        ("Default", .gray), // Thêm Default với màu gray (thay đổi màu mặc định)
        ("Blue", .blue),
        ("Green", .green),
        ("Pink", .pink),
        ("Purple", .purple),
        ("Red", .red),
        ("Black", .black),
        ("Yellow", .yellow),
        ("Orange", .orange)
    ]
    
    var body: some View {
        NavigationView {
            List {
                //Darkmode
                Section(header: Text("Appearance").font(.headline)) {
                    Toggle(isOn: $isDarkMode) {
                        Text("Dark Mode").font(.body)
                    }
                    //Giao diện chuyển sang Darkmode hoặc Lightmode
                    .onChange(of: isDarkMode) { _, newValue in
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            windowScene.windows.first?.overrideUserInterfaceStyle = newValue ? .dark : .light
                        }
                    }
                }
                
                //Pure Color
                Section(header: Text("Pure Color").font(.headline)) {
                    ForEach(colors, id: \.name) { color in
                        HStack {
                            if color.name == "Default" {
                                Circle()
                                    .fill(Color.gray.opacity(0.3)) // Màu nhạt để biểu thị "Default"
                                    .frame(width: 20, height: 20)
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1)) // Viền để nổi bật
                            } else {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 20, height: 20)
                            }
                            Text(color.name)
                            Spacer()
                            if themeColor == color.name { //So sánh với ThemeColor
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            themeColor = color.name // Lưu tên màu vào AppStorage
                        }
                    }
                }
                
                // Texture
                Section(header: Text("Texture").font(.headline)) {
                    Text("Coming Soon")
                        .foregroundColor(.gray)
                }
                
                // Scenery
                Section(header: Text("Scenery").font(.headline)) {
                    Text("Coming Soon")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Theme")
            .background(selectedThemeColor.opacity(0.5)) // Dùng trực tiếp từ Environment
        }
        .onAppear {
            //Đồng bộ với trạng thái Dark Mode ban đầu
            isDarkMode = colorScheme == .dark
        }
    }
}

#Preview {
    // Cung cấp NavigationStack để Preview không crash
    NavigationStack {
        ThemeView()
    }
}
