@State var items = ["Foo", "Bar"]

var body: some View {

  List($items, id: \.self, editActions: .move) { $item in
  Text(item)
    .moveDisabled(item == "Foo")
}
.environment(\.editMode, .constant(.active))
}