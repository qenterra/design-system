@State private var text = "foo"

var body: some View {
    HStack {
        Text(text)

        RenameButton()
            .padding(.leading)
            .renameAction {
                text = "bar"
            }
        }
    }