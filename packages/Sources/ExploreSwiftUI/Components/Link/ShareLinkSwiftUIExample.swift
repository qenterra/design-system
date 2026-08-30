HStack {
    ShareLink(item: URL(string: "https://exploreswiftui.com")!)
    ShareLink("Explore SwiftUI", item: URL(string: "https://exploreswiftui.com")!)
    .padding(.horizontal)
    ShareLink(item: URL(string: "https://exploreswiftui.com")!) {
        Label("Foo", systemImage: "cube.transparent")
    }
}