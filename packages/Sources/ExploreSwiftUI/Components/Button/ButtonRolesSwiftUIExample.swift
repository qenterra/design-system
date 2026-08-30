VStack {
    HStack {
        Button("Tap Me", role: .cancel, action: action)
            .buttonStyle(.plain)
        Button("Tap Me", role: .cancel, action: action)
            .buttonStyle(.borderless)
        Button("Tap Me", role: .cancel, action: action)
            .buttonStyle(.bordered)
        Button("Tap Me", role: .cancel, action: action)
            .buttonStyle(.borderedProminent)
    }
    HStack {
        Button("Tap Me", role: .destructive, action: action)
            .buttonStyle(.plain)
        Button("Tap Me", role: .destructive, action: action)
            .buttonStyle(.borderless)
        Button("Tap Me", role: .destructive, action: action)
            .buttonStyle(.bordered)
        Button("Tap Me", role: .destructive, action: action)
            .buttonStyle(.borderedProminent)
    }
}
