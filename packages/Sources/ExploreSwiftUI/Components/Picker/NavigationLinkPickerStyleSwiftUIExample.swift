NavigationStack {
    List {
        Picker(selection: $selection) {
            Text("1")
                .tag("1")
            Section("Bar") {
                Text("2")
                    .tag("2")
            }
            Label("3", systemImage: "3.circle")
                .tag("3")
        } label: {
            Label("Foo", systemImage: "hand.tap")
            Text("Bar")
        } currentValueLabel: {
            Text("Selected: \(selection)")
        }
        .pickerStyle(.navigationLink)
    }
}
