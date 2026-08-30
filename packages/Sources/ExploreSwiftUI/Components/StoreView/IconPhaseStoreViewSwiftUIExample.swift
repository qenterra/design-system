StoreView(ids: ["auto_renewable_subscription_1", "non_consumable_1"]) { _, productIconPhase in
    switch productIconPhase {
        case .loading:
        Label("Loading", systemImage: "arrow.2.circlepath.circle")
        case .failure(let error):
        Label("Error: \(error.localizedDescription)", systemImage: "exclamationmark.circle")
        case .unavailable:
        Label("Unavailable", systemImage: "questionmark")
        case .success(let promotedIcon):
        promotedIcon
            .resizable()
            .scaledToFit()
    }
} placeholderIcon: {
    ProgressView()
}