var body: some View {
    TabView {
        Tab("1", systemImage: "1.circle") {
            List {
                ForEach(0 ..< 100, id: \.self) {
                    Text("Item \($0)")
                }
            }
        }

        Tab("2", systemImage: "2.circle") {
            EmptyView()
        }

        Tab("3", systemImage: "3.circle") {
            EmptyView()
        }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            AccessoryContent()
        }
    }

    struct AccessoryContent: View {
        @Environment(\.tabViewBottomAccessoryPlacement) var placement

        var body: some View {
            switch placement {
                case .inline:
                Text("Inline")
                case .expanded:
                Text("Expanded")
                case .none:
                Text("")
            }
        }
    }