SubscriptionStoreView(groupID: "457464AA") {
    SubscriptionOptionGroup("Monthly") { product in
        product.subscription?.subscriptionPeriod.unit == .month
    }

    SubscriptionOptionGroup("Yearly") { product in
        product.subscription?.subscriptionPeriod.unit == .year
    }
}