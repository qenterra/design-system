let items = ["Foo", "Bar"]

var body: some View {
  List {
    Section("Header") {
      ForEach(items, id: \.self) { item in
      Text(item)
        .deleteDisabled(item == "Foo")
    }.onDelete { _ in
    action()
  }
}
}
.environment(\.editMode, .constant(.active))
}