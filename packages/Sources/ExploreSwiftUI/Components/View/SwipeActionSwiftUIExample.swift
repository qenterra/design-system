@State private var isSwiped = false

var body: some View {
    VStack {
        Text("Trailing Swipe")
            .swipeActions {
                Button(role: .destructive, action: action)
            }
         Text("Leading Swipe")
             .swipeActions(edge: .leading) {
                 Button(role: .destructive, action: action)
             }
          Text("Stateful Swipe")
              .swipeActions {
                  Button(role: .destructive, action: action)
              } onPresentationChanged: {
                  isSwiped = $0
              }
           Text("Swipe state: \(isSwiped ? "active" : "inactive")")
    }
}
