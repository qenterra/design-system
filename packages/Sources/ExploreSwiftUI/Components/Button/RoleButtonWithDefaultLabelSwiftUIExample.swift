NavigationStack {
    VStack {
        Button(role: .cancel, action: action)
        Button(role: .close, action: action)
        Button(role: .confirm, action: action)
        Button(role: .destructive, action: action)
        Spacer()
    }
    .toolbar {
        Button(role: .cancel, action: action)
        Button(role: .close, action: action)
        Button(role: .confirm, action: action)
        Button(role: .destructive, action: action)
    }
}