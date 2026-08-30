@State var selection = "1"
let pickerOptions = ["1", "2", "3"]

var body: some View {
    List {
        Picker("Foo", selection: $selection) {
            ForEach(pickerOptions, id: \.self) { option in
                Text(option)
            }
        } currentValueLabel: {
            Text("Current: \(selection)")
        }
    }
}