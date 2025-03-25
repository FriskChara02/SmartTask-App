import SwiftUI

struct ButtonAddTasksView: View {
    let action: () -> Void // Đổi 'var' thành 'let' để rõ ràng hơn
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                Image(systemName: "leaf.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
    }
}

#Preview {
    ButtonAddTasksView(action: {}) // 1 closure rỗng nhaaa
}
