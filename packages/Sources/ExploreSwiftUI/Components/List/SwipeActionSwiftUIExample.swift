List {
  Section("Header") {
    Text("Foo")
      .swipeActions(edge: .leading, allowsFullSwipe: false) {
      Button("Action", systemImage: "bolt", action: action)
        .tint(.accentColor)
    }
    Text("Bar")
  }
}