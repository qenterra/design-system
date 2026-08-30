struct Item {
    let message: String
}

@State var item: Item? = .init(message: "Foo")

var body: some View {
    Text("Foo")
        .alert("Title", item: $item) { alertItem in
            Button("Ok") {
                print("Item nilled")
            }
        } message: { alertItem in
            Text(alertItem.message)
        }
}