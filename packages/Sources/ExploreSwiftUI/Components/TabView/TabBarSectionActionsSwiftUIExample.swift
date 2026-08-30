TabView {
    Tab {
        Text("0")
    }

    TabSection("Foo") {
        Tab("1", systemImage: "1.circle") {
            Text("1")
        }
    }
    .sectionActions {
        Button("Bar", systemImage: "plus", action: action)
    }

    Tab("2", image: "cats24x24") {
        Text("2")
    }

    Tab {
        Text("3")
    } label: {
        Label("3", systemImage: "3.circle")
    }
}
.tabViewStyle(.sidebarAdaptable)