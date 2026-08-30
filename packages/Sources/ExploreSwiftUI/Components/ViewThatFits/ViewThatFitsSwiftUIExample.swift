var body: some View {
  VStack(alignment: .leading) {
    testContent
      .background(.red)
      .frame(maxWidth: 300)
    testContent
      .background(.red.secondary)
      .frame(maxWidth: 200)
    testContent
      .background(.red.tertiary)
      .frame(maxWidth: 100)
    testContent
      .background(.red.quaternary)
      .frame(maxWidth: 50)
  }
}

@ViewBuilder
var testContent: some View {
  ViewThatFits {
    Text("Available width 300")
      .frame(width: 300, height: 20)
      .foregroundStyle(.white)
    Text("Available width 200")
      .frame(width: 200, height: 20)
      .foregroundStyle(.white)
    Text("A. w. 100")
      .frame(width: 100, height: 20)
      .foregroundStyle(.white)
    Text("Fallback")
      .frame(width: 80, height: 20)
      .foregroundStyle(.white)
  }
}