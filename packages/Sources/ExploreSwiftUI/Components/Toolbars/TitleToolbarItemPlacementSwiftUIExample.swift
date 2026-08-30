NavigationStack {
  Text("Foo")
    .toolbar {
    ToolbarItem(placement: .largeTitle) {
      Text("1")
    }
    ToolbarItem(placement: .title) {
      Text("2")
    }
    ToolbarItem(placement: .subtitle) {
      Text("3")
    }
    ToolbarItem(placement: .largeSubtitle) {
      Text("4")
    }
  }
}