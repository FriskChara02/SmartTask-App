import SwiftUI

struct SectionHeaderView: View {
    let title: String
    
    @Environment(\.themeColor) var themeColor
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(themeColor)
            .padding(.top, 10)
    }
}

#Preview {
    SectionHeaderView(title: "Example Title") // ✅ Truyền tiêu đề mẫu
}
