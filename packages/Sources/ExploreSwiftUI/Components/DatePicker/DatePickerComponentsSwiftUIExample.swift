@State var date = Date()

var body: some View {
    VStack {
        DatePicker("Select Date", selection: $date, displayedComponents: .date)
        DatePicker("Select Date", selection: $date, displayedComponents: .hourAndMinute)
    }
}