let imageURL = URL(string: "https://exploreswiftui.com/images/cats.jpg")!
let imageSession: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = [
        "X-Custom-Header": "CustomValue"
    ]

    return URLSession(configuration: configuration)
}()

var body: some View {
    AsyncImage(request: URLRequest(url: imageURL)) { image in
        image
    } placeholder: {
        ProgressView()
    }
    .asyncImageURLSession(imageSession)
}