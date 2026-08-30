VStack {
    ControlGroup {
        Button("Increase", systemImage: "plus", action: action)
        Button("Decrease", systemImage: "minus", action: action)
    } label: {
        Text("Foo")
    }
    ControlGroup("Foo", systemImage: "magnifyingglass") {
        Button("Increase", systemImage: "plus", action: action)
        Button("Decrease", systemImage: "minus", action: action)
    }
    ControlGroup {
        Button("Increase", systemImage: "plus", action: action)
        Button("Decrease", systemImage: "minus", action: action)
    }
}
.controlGroupStyle(.compactMenu)