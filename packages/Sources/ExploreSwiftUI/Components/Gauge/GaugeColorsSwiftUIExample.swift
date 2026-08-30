@State private var currentValue = 0.42

var body: some View {
    VStack {
        HStack {
            Gauge(value: currentValue) {
                Text("Foo")
            } currentValueLabel: {
                Text("42")
                    .foregroundColor(.indigo)
            } minimumValueLabel: {
                Text("0")
                    .foregroundColor(.mint)
            } maximumValueLabel: {
                Text("100")
                    .foregroundColor(.blue)
            }
            .gaugeStyle(.accessoryCircular)

            Gauge(value: currentValue) {
                Text("Foo")
            } currentValueLabel: {
                Text("42")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("100")
            }
            .gaugeStyle(.accessoryCircularCapacity)
        }
        Gauge(value: currentValue) {
            Text("Foo")
        } currentValueLabel: {
            Text("42")
        } minimumValueLabel: {
            Text("0")
        } maximumValueLabel: {
            Text("100")
        }
        .gaugeStyle(.linearCapacity)
        Gauge(value: currentValue) {
            Text("Foo")
        } currentValueLabel: {
            Text("42")
        } minimumValueLabel: {
            Text("0")
        } maximumValueLabel: {
            Text("100")
        }
        .gaugeStyle(.accessoryLinear)

        Gauge(value: currentValue) {
            Text("Foo")
        } currentValueLabel: {
            Text("42")
        } minimumValueLabel: {
            Text("0")
        } maximumValueLabel: {
            Text("100")
        }
        .gaugeStyle(.accessoryLinearCapacity)
    }
    .tint(Gradient(colors: [.green, .orange, .red]))
        .foregroundStyle(.brown)
}