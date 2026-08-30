Slider(value: $percentage) {
            Text("Percentage")
        } currentValueLabel: {
            Text("\(percentage)%")
        } ticks: {
            SliderTickContentForEach(
                stride(from: 0.0, through: 1.0, by: 0.25).map { $0 },
                id: \.self
            ) { value in
                SliderTick(value) {
                    Text("value: \(value * 100)%")
                }
            }
        }
        .padding(.horizontal)