import SwiftUI

struct EditCategoryView: View {
    @EnvironmentObject var categoryVM: CategoryViewModel
    @Environment(\.dismiss) var dismiss
    
    let category: Category
    @State private var name: String
    @State private var selectedColor: String
    @State private var selectedIcon: String
    @State private var showTooltip: Bool = false
    
    let colors: [(name: String, color: Color)] = [
        ("blue", .blue),
        ("purple", .purple),
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green)
    ]
    let icons1 = ["person.crop.circle.fill", "star", "heart", "bell", "bookmark"]
    let icons2 = ["folder.circle.fill", "paperplane.fill", "birthday.cake.fill", "graduationcap", "book.fill"]
    let icons3 = ["cup.and.heat.waves.fill", "list.bullet.clipboard.fill", "sparkles.tv", "camera.fill", "cloud.moon.rain"]
    let icons4 = ["cart.fill", "gift.fill", "envelope.fill", "fork.knife", "airplane"]
    
    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name)
        _selectedColor = State(initialValue: category.color ?? "blue")
        _selectedIcon = State(initialValue: category.icon ?? "pencil")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Name")) {
                    TextField("Name", text: $name)
                }
                
                Section(header: HStack {
                    Text("Color")
                    Button(action: {
                        showTooltip.toggle()
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }) {
                    VStack(alignment: .leading, spacing: 10) {
                        if showTooltip {
                            Text("The color will be displayed in the calendar interface.\n\"moon.stars\" is the theme color")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity)
                        }
                        
                        HStack(spacing: 15) {
                            ForEach(colors, id: \.name) { color in
                                ZStack {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .inset(by: 3)
                                                .stroke(Color.white, lineWidth: selectedColor == color.name ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColor = color.name
                                        }
                                    
                                    if color.name == "blue" {
                                        Image(systemName: "moon.stars")
                                            .foregroundColor(.white)
                                            .font(.system(size: 20))
                                    }
                                }
                            }
                        }
                    }
                }
                .animation(.easeInOut, value: showTooltip)
                
                Section(header: Text("Icon")) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            // Hàng 1
                            HStack(spacing: 30) {
                                ForEach(icons1, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedIcon == icon ? selectedIconColor : .gray)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? Color.gray.opacity(0.1) : Color.clear)
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            selectedIcon = icon
                                        }
                                }
                            }
                            
                            // Hàng 2
                            HStack(spacing: 30) {
                                ForEach(icons2, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedIcon == icon ? selectedIconColor : .gray)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? Color.gray.opacity(0.1) : Color.clear)
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            selectedIcon = icon
                                        }
                                }
                            }
                            
                            // Hàng 3
                            HStack(spacing: 30) {
                                ForEach(icons3, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedIcon == icon ? selectedIconColor : .gray)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? Color.gray.opacity(0.1) : Color.clear)
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            selectedIcon = icon
                                        }
                                }
                            }
                            
                            // Hàng 4
                            HStack(spacing: 30) {
                                ForEach(icons4, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedIcon == icon ? selectedIconColor : .gray)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? Color.gray.opacity(0.1) : Color.clear)
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            selectedIcon = icon
                                        }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200) // Giới hạn chiều cao để cuộn nếu cần
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }.foregroundColor(.red),
                trailing: Button("Save") {
                    saveCategory()
                    dismiss()
                }.foregroundColor(.blue)
            )
        }
    }
    
    private var selectedIconColor: Color {
        if let color = colors.first(where: { $0.name == selectedColor }) {
            return color.color.opacity(0.7)
        }
        return .gray
    }
    
    private func saveCategory() {
        var updatedCategory = category
        updatedCategory.name = name
        updatedCategory.color = selectedColor
        updatedCategory.icon = selectedIcon
        categoryVM.updateCategory(category: updatedCategory)
    }
}

#Preview {
    EditCategoryView(category: Category(id: 1, name: "Work"))
        .environmentObject(CategoryViewModel())
}
