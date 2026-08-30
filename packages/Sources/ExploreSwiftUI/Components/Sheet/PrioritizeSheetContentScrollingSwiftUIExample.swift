@State var showSheet = true

var body: some View {
    Text("Foo")
        .sheet(isPresented: $showSheet) {
            ScrollView {
                ForEach(0 ..< 50) { i in
                    Text("Bar \(i)")
                }
            }
            .presentationDetents([.medium, .large])
            .presentationContentInteraction(.scrolls)
        }
}