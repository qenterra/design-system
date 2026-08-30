@State var showAppStoreOverlay = false

var body: some View {
    Button("Manage subscriptions") {
        showAppStoreOverlay = true
    }
    .appStoreOverlay(isPresented: $showAppStoreOverlay) {
        SKOverlay.AppConfiguration(appIdentifier: "1234567890", position: .bottom)
    }
}