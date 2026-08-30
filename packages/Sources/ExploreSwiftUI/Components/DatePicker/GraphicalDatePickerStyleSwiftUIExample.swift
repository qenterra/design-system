@State var date = Date()

var body: some View {
    DatePicker("Select Date", selection: $date, displayedComponents: .date)
        .datePickerStyle(.graphical)
}