Text("Buttons")
    .contextMenu {
        Button("Button 1", action: action)
        Button("Button 2", systemImage: "button.vertical.left.press", action: action)
        Button(action: action) {
            Text("Button 3")
            Text("Description 3")
        }
    } preview: {
        Text("Custom Preview")
            .padding()
    }