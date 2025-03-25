import SwiftUI

struct EventsView: View {
    var body: some View {
        NavigationView {
            Text("📅 Danh sách sự kiện sẽ hiển thị ở đây")
                .navigationTitle("Sự kiện")
        }
    }
}

#Preview {
    EventsView()
}
