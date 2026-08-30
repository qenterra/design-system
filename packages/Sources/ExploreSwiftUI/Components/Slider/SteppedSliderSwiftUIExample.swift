@State private var speed = 40.0
@State private var isEditing = false

var body: some View {
  Slider(
  value: $speed,
  in: 0 ... 100,
  step: 10,
  label: {
    Text("Foo") // for accessibility, enables ticks
  },
  onEditingChanged: { editing in
  isEditing = editing
}
)
}