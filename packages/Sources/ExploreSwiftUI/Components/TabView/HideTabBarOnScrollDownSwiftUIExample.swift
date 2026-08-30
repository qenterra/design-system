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