VStack {
    Button("Tap Me", action: action)
        .buttonStyle(.borderedProminent)
        .controlSize(.mini)
    Button("Tap Me", action: action)
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
    Button("Tap Me", action: action)
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
    Button("Tap Me", action: action)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    Button("Tap Me", action: action)
        .buttonStyle(.borderedProminent)
    // only on visionOS bigger than large
        .controlSize(.extraLarge)

}
