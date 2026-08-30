struct TreeItem: Identifiable {
  let id = UUID()
  let name: String
  let children: [TreeItem]?

  init(_ name: String, children: [TreeItem]? = nil) {
    self.name = name
    self.children = children
  }
}

let data = [
TreeItem("Header", children: [
TreeItem("Foo", children: [
TreeItem("Foo 1"),
TreeItem("Foo 2")
]),
TreeItem("Bar", children: [
TreeItem("Bar 1"),
TreeItem("Bar 2")
])
])
]

var body: some View {
  List {
    OutlineGroup(data, children: \.children) { item in
    Text(item.name)
  }
}
}