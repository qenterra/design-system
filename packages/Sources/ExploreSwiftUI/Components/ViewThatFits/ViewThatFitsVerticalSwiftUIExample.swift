var body: some View {
  VStack(alignment: .leading) {
    testContent
      .background(.red)
      .frame(maxWidth: 200)
    testContent
      .background(.red.secondary)
      .frame(maxHeight: 20)
    testContent
      .background(.red.tertiary)
      .frame(maxHeight: 9)
  }
}

@ViewBuilder
var testContent: some View {
  ViewThatFits(in: .vertical) {
    Text("Size w300 h30")
      .frame(width: 300, height: 30)
      .foregroundStyle(.white)
    Text("Size w200 h20")
      .frame(width: 200, height: 20)
      .foregroundStyle(.white)
    Text("Fallback")
      .frame(width: 80, height: 10)
      .foregroundStyle(.white)
  }
}