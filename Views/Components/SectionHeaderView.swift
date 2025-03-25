import SwiftUI

struct SectionHeaderView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.blue)
            .padding(.top, 10)
    }
}

#Preview {
    SectionHeaderView(title: "Example Title") // ✅ Truyền tiêu đề mẫu
}
