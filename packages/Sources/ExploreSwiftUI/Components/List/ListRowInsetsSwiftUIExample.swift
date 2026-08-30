List {
  Section {
    Text("All")
  } header: {
    Text("Header")
  }
  .listRowInsets(.all, 0)
  Section {
    Text("Header Only")
  } header: {
    Text("Header")
      .listRowInsets(.all, 0)
  }
  Section {
    Text("Normal")
  } header: {
    Text("Header")
  }
}