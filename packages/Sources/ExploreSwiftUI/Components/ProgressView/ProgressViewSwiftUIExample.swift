let workoutDateRange = Date()...Date().addingTimeInterval(5*60)

var body: some View {
    VStack {
        HStack(alignment: .top) {
            ProgressView()
            ProgressView("Foo")
        }
        HStack(alignment: .top) {
            ProgressView(value: 0.42)
                .padding(.top)
            ProgressView(value: 42, total: 100)
                .padding(.vertical)
        }
        ProgressView(timerInterval: 0.42)
            .padding(.bottom)
        ProgressView(value: 0.42) {
            Text("Foo")
        } currentValueLabel: {
            Text("bar")
        }
    }
}