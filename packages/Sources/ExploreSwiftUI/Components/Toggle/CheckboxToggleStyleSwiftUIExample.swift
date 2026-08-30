@State var isOn = false

var body: some View {
    List {
        Toggle("Foo1", isOn: $isOn)
        Toggle("Foo2", image: .cats24X24, isOn: $isOn)
        Toggle("Foo3", systemImage: "star", isOn: $isOn)
        Toggle(isOn: $isOn) {
            Label("Foo4", systemImage: "star")
            Text("Bar")
        }
        Toggle("Foo5", isOn: .constant(true))
    }
    .toggleStyle(.checkbox)
}