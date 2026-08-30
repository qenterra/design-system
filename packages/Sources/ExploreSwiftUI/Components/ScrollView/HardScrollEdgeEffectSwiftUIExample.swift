NavigationStack {
  List {
    ForEach(0 ..< 100, id: \.self) {
      Text("Item \($0)")
    }
  }
  .toolbar {
    Button("foo", action: action)
  }
  .scrollEdgeEffectStyle(.hard, for: .all)
}