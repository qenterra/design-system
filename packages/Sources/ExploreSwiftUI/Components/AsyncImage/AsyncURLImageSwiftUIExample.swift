let imageURL = URL(string: "https://exploreswiftui.com/images/cats.jpg")!

var body: some View {
    AsyncImage(request: URLRequest(url: imageURL))
}