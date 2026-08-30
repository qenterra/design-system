List {
  Section {
    Toggle("Toggle", isOn: .constant(true))
    TextField("TextField", text: .constant(""))
    Button("Button", action: action)
    Picker("Picker", selection: .constant(0)) {
      Text("Option 1").tag(0)
    }
  }

  Text("Foo")

  Section {
    Text("Bar1")
    Text("Bar2")
  } header: {
    Text("Header")
  } footer: {
    Text("Footer")
  }
}
.listStyle(.plain)