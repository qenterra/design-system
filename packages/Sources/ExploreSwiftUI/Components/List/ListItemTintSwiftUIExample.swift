List {
  Section("Header") {
    Text("Foo")
    Button("Bar", action: action)
    Label("FooBar", systemImage: "trash")
  }
  .listItemTint(.green)
}