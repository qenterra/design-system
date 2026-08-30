@State private var pastedText: String = ""

var body: some View {
    PasteButton(payloadType: String.self) { strings in
        pastedText = strings[0]
    }
}