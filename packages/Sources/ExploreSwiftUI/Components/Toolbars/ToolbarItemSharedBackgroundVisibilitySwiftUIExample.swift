NavigationStack {
  Text("Foo")
    .toolbar {
    ToolbarItem {
      Button("Account", systemImage: "person.circle", action: action)
    }
    ToolbarItem {
      Button("Account", systemImage: "person.circle", action: action)
    }
    .sharedBackgroundVisibility(.hidden)
  }
}