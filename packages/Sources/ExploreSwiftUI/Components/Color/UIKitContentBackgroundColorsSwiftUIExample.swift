VStack {
  List {
    Section {
      Text("content")
    }
  }
  .frame(maxHeight: 50)
  HStack {
    smallRect
    // can also be used as inverted text color
      .foregroundStyle(Color(.systemBackground))
    smallRect
    // GroupBox content backgroud
      .foregroundStyle(Color(.secondarySystemBackground))
    smallRect
      .foregroundStyle(Color(.tertiarySystemBackground))
    smallRect
    // can also be used as inverted text color
    // List background
      .foregroundStyle(Color(.systemGroupedBackground))
    smallRect
    // List content background
      .foregroundStyle(Color(.secondarySystemGroupedBackground))
    smallRect
      .foregroundStyle(Color(.tertiarySystemGroupedBackground))
  }
  GroupBox {
    Text("content")
  }
  .frame(maxHeight: 50)
}