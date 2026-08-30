HStack {
    Button("Tap Me", action: action)
    Button("Tap Me", systemImage: "hand.tap", action: action)
        .padding(.horizontal)
    Button(action: action) {
        Text("Tap Me")
        Image(systemName: "hand.tap")
    }
}