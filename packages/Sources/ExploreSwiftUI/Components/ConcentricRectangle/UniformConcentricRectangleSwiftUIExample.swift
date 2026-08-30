ZStack(alignment: .bottom) {
    // Respects the device frame's corner radius
    ConcentricRectangle(corners: .concentric, isUniform: true)
        .fill(Color.blue)
        .frame(height: 50)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(30)
        .ignoresSafeArea()

    ZStack {
        // Gets radius from parent rect
        ConcentricRectangle()
            .fill(.secondary)

        // Respects the parent rectangle's corner radius
        ConcentricRectangle(corners: .concentric, isUniform: true)
            .fill(.red)
            .frame(width: 200, height: 200)
            .padding([.trailing, .bottom])
    }
    .containerShape(
            .rect(cornerRadius: 42)
    )
    .frame(width: 250, height: 250)
        .padding(.bottom)
}