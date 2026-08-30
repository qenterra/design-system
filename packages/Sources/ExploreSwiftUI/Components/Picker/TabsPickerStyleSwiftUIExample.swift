Picker("Foo", selection: $selection) {
    Text("1")
        .tag("1")

    Section("Bar") {
        Text("2")
            .tag("2")
    }
    Text("3")
        .tag("3")
}
.pickerStyle(.tabs)