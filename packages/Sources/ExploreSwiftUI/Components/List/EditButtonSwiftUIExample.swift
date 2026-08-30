@State var items = ["Foo", "Bar"]

var body: some View {
  NavigationView {
    List {
      ForEach(items, id: \.self) { item in
      Text(item)
    }
    .onDelete { _ in action() }
    .onMove { _, _ in action() }
  }
  .toolbar {
    EditButton()
  }
}
}