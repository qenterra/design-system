let items = ["Foo", "Bar"]

var body: some View {
  List(items, id: \.self) { item in
  Section(item) {
    ForEach(0 ..< 42) { number in
    Text(String(describing: number))
  }
}
.sectionIndexLabel(item)
}
.listSectionIndexVisibility(.visible)

}