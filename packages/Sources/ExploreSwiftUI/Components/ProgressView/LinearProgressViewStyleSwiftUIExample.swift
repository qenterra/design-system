VStack {
    ProgressView("Foo")
    ProgressView(value: 0.42) {
        Text("Foo")
    } currentValueLabel: {
        Text("bar")
    }
}
.progressViewStyle(.linear)