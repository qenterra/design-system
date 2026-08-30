TabView {
    Tab {
        EmptyView()
    }
    Tab("1", systemImage: "1.circle", role: .search) {
        EmptyView()
    }

    Tab("2", image: "cats24x24") {
        EmptyView()
    }
    Tab {
        EmptyView()
    } label: {
        Label("3", systemImage: "3.circle")
    }
}