 @State var showManageSubscriptions = false

    var body: some View {
        Button("Manage subscriptions") {
            showManageSubscriptions = true
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
    }