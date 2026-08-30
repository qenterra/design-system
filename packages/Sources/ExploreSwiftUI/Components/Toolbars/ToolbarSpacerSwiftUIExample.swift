content
  .toolbar {
  ToolbarItemGroup(placement: .primaryAction) {
    Button("Up", systemImage: "chevron.up", action: action)
    Button("Down", systemImage: "chevron.down", action: action)
  }
  ToolbarSpacer(.fixed, placement: .primaryAction)
  ToolbarItem(placement: .primaryAction) {
    Button("Settings", systemImage: "ellipsis", action: action)
  }
}