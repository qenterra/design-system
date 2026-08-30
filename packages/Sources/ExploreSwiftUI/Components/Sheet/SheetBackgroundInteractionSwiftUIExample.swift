@State var showSheet = true

var body: some View {
    Button("You can still tap on me with the sheet open") {
        showSheet.toggle()
    }
    .padding(.bottom, 120)
    .sheet(isPresented: $showSheet) {
        sheetContent
            .presentationDetents([.medium])
            .presentationBackgroundInteraction(.enabled)
    }
}