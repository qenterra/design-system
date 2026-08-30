enum FooError: LocalizedError {
    case bar

    var errorDescription: String? {
        switch self {
            case .bar:
            return "Bar error occurred."
        }
    }

    var message: String {
        switch self {
            case .bar:
            return "This is a message for the Bar error."
        }
    }
}

@State private var error: FooError? = .bar

var body: some View {
    Text("Foo")
        .alert(error: $error) { errorItem in
            Button("OK") {
                print("\(errorItem) nilled")
            }
        } message: { errorItem in
            Text(errorItem.message)
        }
}