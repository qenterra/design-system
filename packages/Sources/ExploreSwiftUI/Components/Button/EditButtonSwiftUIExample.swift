@Environment(\.editMode) private var editMode
@State private var name = "Foo"

var body: some View {
    HStack {
        if editMode?.wrappedValue.isEditing == true {
            TextField("Name", text: $name)
        } else {
            Text(name)
        }
        EditButton()
    }
}