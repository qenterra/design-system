@State private var currentValue = 0.42

var body: some View {
    HStack {
        Gauge(value: currentValue) {
            Text("Foo")
        }

        Gauge(value: currentValue) {
            Text("Foo")
        } currentValueLabel: {
            Text("\(currentValue)")
        }
        .padding(.horizontal)

        Gauge(value: currentValue) {
            Text("Foo")
        } currentValueLabel: {
            Text("42")
        } minimumValueLabel: {
            Text("0")
        } maximumValueLabel: {
            Text("100")
        }
    }
    .gaugeStyle(.accessoryCircularCapacity)
}