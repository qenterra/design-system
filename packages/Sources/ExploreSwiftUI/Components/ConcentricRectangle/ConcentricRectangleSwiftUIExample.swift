ZStack(alignment: .bottom) {
            // Respects radius from devide frame
            ConcentricRectangle()
                .fill(Color.blue)
                .frame(height: 50)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(30)
                .ignoresSafeArea()

            ZStack {
                // Gets radius from parent rect
                ConcentricRectangle()
                    .fill(.secondary)

                // Respects radius from parent rect
                ConcentricRectangle()
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