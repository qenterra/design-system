NavigationSplitView {
    Text("Foo")
        .containerBackground(.thinMaterial, for: .navigation)
        .containerBackground(.blue.gradient, for: .navigationSplitView)
} detail: {
    Text("Bar")
        .containerBackground(.ultraThinMaterial, for: .navigation)
}