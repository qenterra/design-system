VStack {
            AsyncImage(request: URLRequest(url: slowURL)) { image in
                image.resizable(resizingMode: .tile)
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }

            AsyncImage(request: URLRequest(url: imageURL)) { image in
                image.resizable(resizingMode: .tile)
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(height: 100)
        }