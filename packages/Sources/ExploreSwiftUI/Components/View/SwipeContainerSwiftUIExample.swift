VStack {
    Section("Group1") {
        Text("Foo1")
            .swipeActions {
                Button(role: .destructive, action: action)
            }
            Text("Bar1")
                .swipeActions {
                    Button(role: .destructive, action: action)
                }
            }
            .swipeActionsContainer()
            Text("Foo2")
                .swipeActions {
                    Button(role: .destructive, action: action)
                }
                Text("Bar2")
                    .swipeActions {
                        Button(role: .destructive, action: action)
                    }
                }