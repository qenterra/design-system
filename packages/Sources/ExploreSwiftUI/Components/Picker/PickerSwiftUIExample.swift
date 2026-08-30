@State var selection = "1"
let pickerOptions = ["1", "2", "3"]

var body: some View {
    List {
        Picker("Foo", selection: $selection) {
            ForEach(pickerOptions, id: \.self) { option in
                Text(option)
            }
        }
        Picker("Bar", systemImage: "hand.tap", selection: $selection) {
            ForEach(pickerOptions, id: \.self) { option in
                Text(option)
            }
        }
        Picker("Bar", image: .cats24X24, selection: $selection) {
            ForEach(pickerOptions, id: \.self) { option in
                Text(option)
            }
        }
        Picker(selection: $selection) {
            ForEach(pickerOptions, id: \.self) { option in
                Text(option)
            }
        } label: {
            Label("Foo", systemImage: "star")
            Text("Bar")
        }
    }
}