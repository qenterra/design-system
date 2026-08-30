Link("Explore SwiftUI", destination: URL(string: "https://exploreswiftui.com")!)
    .environment(\.openURL, OpenURLAction { url in
        print("Open \(url)")
        return .handled
    })