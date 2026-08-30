struct IdentifableItem: Identifiable {
    let id = UUID()
}

@State var item: IdentifableItem? = .init()

var body: some View {
    Text("Foo")
        .sheet(item: $item) { itm in
            sheetContent(item)
        }
}