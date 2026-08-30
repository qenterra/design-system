@AppStorage("tabCustomization") private var customization: TabViewCustomization

var body: some View {
    TabView {
        Tab {
            Text("0")
        }
        .customizationID("com.myApp.0")

        Tab("1", systemImage: "1.circle") {
            Text("1")
        }
        .customizationID("com.myApp.1")

        Tab("2", image: "cats24x24") {
            Text("2")
        }
        .customizationID("com.myApp.2")

        Tab {
            Text("3")
        } label: {
            Label("3", systemImage: "3.circle")
        }
        .customizationID("com.myApp.3")
    }
    .tabViewStyle(.sidebarAdaptable)
    .tabViewCustomization($customization)
}