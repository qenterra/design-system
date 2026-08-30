StoreView(ids: ["auto_renewable_subscription_1", "non_consumable_1"]) { product in
    if product.id == "auto_renewable_subscription_1" {
        Image(systemName: "checkmark.seal")
    } else {
        Image(systemName: "cat")
    }
}