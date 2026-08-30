struct Item {}

@State var item: Item? = .init()

var body: some View {
    Text("Foo")
        .alert("Title", item: $item) { alertItem in
            Button("Ok") {
                print("Item nilled")
            }
        }
}