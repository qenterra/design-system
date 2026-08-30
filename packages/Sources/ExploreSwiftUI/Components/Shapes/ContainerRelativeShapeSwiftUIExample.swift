VStack {
    Text("Foo")
    VStack {
        Text("Bar")
        Text("Foo")
            .padding()
            .background(ContainerRelativeShape().fill(Color.green))
    }
    .padding()
        .background(ContainerRelativeShape().fill(Color.red))

}
.padding()
    .background(.blue, in: RoundedRectangle(cornerRadius: 40))