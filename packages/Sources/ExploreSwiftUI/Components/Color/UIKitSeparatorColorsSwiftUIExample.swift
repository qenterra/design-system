VStack {
  Divider()

  HStack {
    smallRect
    // Divider color
      .foregroundStyle(Color(.separator))
    smallRect
      .foregroundStyle(Color(.opaqueSeparator))

    smallRect
    // Divider color
      .foregroundStyle(Color(.separator))
      .background(.orange)
    smallRect
      .foregroundStyle(Color(.opaqueSeparator))
      .background(.orange)
  }
}