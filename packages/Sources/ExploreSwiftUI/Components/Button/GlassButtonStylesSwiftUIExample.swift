VStack {
  HStack {
    Button("Tap Me", action: action)
      .buttonStyle(.glass)
    Button("Tinted Tap Me", action: action)
      .buttonStyle(.glass)
      .tint(.red)
  }
  HStack {
    Button("Tap Me", action: action)
      .buttonStyle(.glassProminent)
    Button("Tap Me", action: action)
      .buttonStyle(.glassProminent)
      .tint(.red)
  }
}