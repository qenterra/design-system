TabView {
    TabSection("Foo") {
        Tab {
            Text("0")
        } label: {
            Text("1")
        }
    }

    TabSection("Bar") {
        Tab {
            Text("2")
        } label: {
            Text("3")
        }
    }
    .defaultSectionExpansion(.collapsed)

    TabSection("FooBar") {
        Tab {
            Text("4")
        } label: {
            Text("5")
        }
    }
}
.tabViewStyle(.sidebarAdaptable)