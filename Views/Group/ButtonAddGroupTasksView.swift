//
//  ButtonAddGroupTasksView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 2/5/25.
//

import SwiftUI

struct ButtonAddGroupTasksView: View {
    @Environment(\.themeColor) var themeColor
    
    let action: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                Image(systemName: "pencil.and.outline")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(themeColor)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding()
        }
    }
}

#Preview {
    ButtonAddGroupTasksView(action: {})
}
