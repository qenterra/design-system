@State var selectedEntry: String? = "Foo"
let entries = ["Foo", "Bar"]

private struct EntryItem: View {
  let text: String

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        EntryItemChild(text: text)
      }
    }
  }
}

private struct EntryItemChild: View {
  let text: String

  @Environment(\.backgroundProminence) private var backgroundProminence

  var body: some View {
    if backgroundProminence == .increased {
      Text(text)
        .bold()
        .italic()
    } else {
      Text(text)
        .foregroundStyle(Color.accentColor)
    }
  }
}

var body: some View {
  VStack {
    List(entries, id: \.self, selection: $selectedEntry) { entry in
    EntryItem(text: entry)
  }
}