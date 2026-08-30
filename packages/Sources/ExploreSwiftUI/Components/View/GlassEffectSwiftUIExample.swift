HStack {
  Text("Foo")
    .padding()
    .glassEffect()
  Text("Foo")
    .padding()
    .glassEffect(in: .rect(cornerRadius: 10))
  Text("Foo")
    .padding()
    .glassEffect(.regular.interactive())
  Text("Foo")
    .padding()
    .glassEffect(.regular.tint(.red))
}