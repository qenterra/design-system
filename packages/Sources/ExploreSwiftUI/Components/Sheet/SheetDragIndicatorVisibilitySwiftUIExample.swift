@State var showSheet = true

var body: some View {
    Text("Foo")
        .sheet(isPresented: $showSheet) {
            sheetContent
                .presentationDragIndicator(.visible)
        }
}