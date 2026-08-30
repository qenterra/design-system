List {
  Section("Header") {
    Text("Foo")
  }
  .listSectionMargins(.horizontal, 0)

  Section {
    Text("Bar")
  } header: {
    Text("Header")
  }
}