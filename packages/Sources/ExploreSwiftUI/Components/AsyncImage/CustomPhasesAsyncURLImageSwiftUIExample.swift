VStack {
    AsyncImage(url: URL(string: "http://slowww.rf.gd")!) { phase in
        if let image = phase.image {
            image
        } else if phase.error != nil {
            Color.red
        } else {
            ProgressView()
        }
    }
    AsyncImage(url: URL(string: "https://exploreswiftui.com")!) { phase in
        if let image = phase.image {
            image
        } else if phase.error != nil {
            Color.red
        } else {
            ProgressView()
        }
    }
    .frame(height: 100)
    AsyncImage(url: URL(string: "https://exploreswiftui.com/images/cats.jpg")!) { phase in
        if let image = phase.image {
            image
                .resizable()
                .scaledToFit()
        } else if phase.error != nil {
            Color.red
        } else {
            ProgressView()
        }
    }
    .frame(height: 100)
}