VStack {
  HStack {
    HStack {
      smallRect
        .foregroundStyle(.ultraThinMaterial)
      smallRect
        .foregroundStyle(.thinMaterial)
      smallRect
        .foregroundStyle(.regularMaterial)
      smallRect
        .foregroundStyle(.thickMaterial)
      smallRect
        .foregroundStyle(.ultraThickMaterial)
    }
  }
  .padding()
    .background {
    meshGradient
  }
  HStack {
    HStack {
      smallRect
        .foregroundStyle(.ultraThinMaterial)
      smallRect
        .foregroundStyle(.thinMaterial)
      smallRect
        .foregroundStyle(.regularMaterial)
      smallRect
        .foregroundStyle(.thickMaterial)
      smallRect
        .foregroundStyle(.ultraThickMaterial)
    }
  }
  .padding()
    .padding(.horizontal)
    .background {
    Image(.cats)
      .resizable()
      .aspectRatio(contentMode: .fill)
      .frame(height: 50)
      .padding()
      .clipped()
  }
}