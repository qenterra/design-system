@State var selection = "1"

var body: some View {
    let displayedSelection = Text("Selected: \(selection)")

    TabView(selection: $selection) {
        Tab(value: "0") {
            displayedSelection
        }
        Tab("1", systemImage: "1.circle", value: "1") {
            displayedSelection
        }

        Tab("2", image: "cats24x24", value: "2") {
            displayedSelection
        }
        Tab(value: "3") {
            displayedSelection
        } label: {
            Label("3", systemImage: "3.circle")
        }
    }
}