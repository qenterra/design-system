VStack {
  HStack {
    smallRect
      .foregroundStyle(.blue)
    smallRect
      .foregroundStyle(.blue.secondary)
    smallRect
      .foregroundStyle(.blue.tertiary)
    smallRect
      .foregroundStyle(.blue.quaternary)
    smallRect
      .foregroundStyle(.blue.quinary)
  }
  HStack {
    smallRect
      .foregroundStyle(.blue.gradient)
    smallRect
      .foregroundStyle(.blue.gradient.secondary)
    smallRect
      .foregroundStyle(.blue.gradient.tertiary)
    smallRect
      .foregroundStyle(.blue.gradient.quaternary)
    smallRect
      .foregroundStyle(.blue.gradient.quinary)
  }
  HStack {
    smallRect
      .foregroundStyle(.blue.gradient.opacity(0.9))
    smallRect
      .foregroundStyle(.blue.gradient.opacity(0.7))
    smallRect
      .foregroundStyle(.blue.gradient.tertiary.opacity(0.5))
    smallRect
      .foregroundStyle(.blue.gradient.quaternary.opacity(0.3))
    smallRect
      .foregroundStyle(.blue.gradient.quinary.opacity(0.1))
  }
}