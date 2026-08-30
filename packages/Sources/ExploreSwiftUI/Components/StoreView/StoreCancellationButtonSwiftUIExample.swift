Text("Foo")
    .sheet(isPresented: .constant(true)) {
        StoreView(ids: ["auto_renewable_subscription_1", "non_consumable_1"])
            .storeButton(.visible, for: .cancellation)
    }