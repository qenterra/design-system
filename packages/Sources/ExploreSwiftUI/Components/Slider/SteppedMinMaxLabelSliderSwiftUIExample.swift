@State private var speed = 42.0
@State private var isEditing = false

var body: some View {
    Slider(
        value: $speed,
        in: 0 ... 100,
        step: 10 // optional, by default 1,
    ) {
        Text("Foo") // for accessibility
    } minimumValueLabel: {
        Text("0")
    } maximumValueLabel: {
        Text("100")
    } onEditingChanged: { editing in // optional
        isEditing = editing
    }
}