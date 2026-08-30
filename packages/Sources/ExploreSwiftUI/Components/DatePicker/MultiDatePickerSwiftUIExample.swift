@State private var dates: Set<DateComponents> = []

var body: some View {
    MultiDatePicker("Dates Available", selection: $dates)
}