List {
    Menu("Test") {
        Picker(selection: $selection) {
            Text("1")
                .tag("1")
            Text("2")
                .tag("2")
            Section("Bar") {
                Text("3")
                    .tag("3")
                Text("4")
                    .tag("4")
            }
            Label("5", systemImage: "5.circle")
                .tag("5")
            Label("6", systemImage: "6.circle")
                .tag("6")
        } label: {
            Label("Foo", systemImage: "hand.tap")
            Text("Bar")
        } currentValueLabel: {
            Text("Selected: \(selection)")
        }
        .pickerStyle(.palette)
    }
}