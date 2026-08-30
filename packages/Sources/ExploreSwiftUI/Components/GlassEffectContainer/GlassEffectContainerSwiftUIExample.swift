VStack {
  GlassEffectContainer(spacing: 40.0) {
    HStack(spacing: 40.0) {
      Image(systemName: "1.circle")
        .frame(width: 80.0, height: 80.0)
        .font(.system(size: 36))
        .glassEffect()
        .offset(x: 30.0, y: 0.0)

      Image(systemName: "2.circle")
        .frame(width: 80.0, height: 80.0)
        .font(.system(size: 36))
        .glassEffect()
        .offset(x: -30.0, y: 0.0)
    }
  }

  HStack(spacing: 40.0) {
    Image(systemName: "1.circle")
      .frame(width: 80.0, height: 80.0)
      .font(.system(size: 36))
      .glassEffect()
      .offset(x: 30.0, y: 0.0)

    Image(systemName: "2.circle")
      .frame(width: 80.0, height: 80.0)
      .font(.system(size: 36))
      .glassEffect()
      .offset(x: -30.0, y: 0.0)
  }

}