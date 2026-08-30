@State var showSheet = true

var body: some View {
    Text("Foo")
        .sheet(isPresented: $showSheet) {
            sheetContent
                .presentationDetents([.medium, .height(200), .fraction(0.1)])
        }
}