enum FooError: LocalizedError {
    case bar

    var errorDescription: String? {
        switch self {
            case .bar:
            return "Bar error occurred."
        }
    }
}

@State private var error: FooError? = .bar

var body: some View {
    Text("Foo")
        .alert(error: $error) {
            Button("OK") {
                print("Error nilled")
            }
        }
}