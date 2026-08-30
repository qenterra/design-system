@State private var speed = 42.0
    
var body: some View {
        Slider(value: $speed) {
            Text("Foo")
        } ticks: {
            SliderTick(0.2)
            SliderTick(0.6)
            SliderTick(0.8)
        }
    }