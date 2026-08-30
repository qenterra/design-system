ContentUnavailableView {
    Label("No Mail", systemImage: "tray.fill")
} description: {
    Text("New mails you receive will appear here.")
} actions: {
    Button("Switch Account") { }
        .buttonStyle(.borderedProminent)
}