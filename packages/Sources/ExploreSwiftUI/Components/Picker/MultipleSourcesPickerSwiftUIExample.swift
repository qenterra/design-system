enum SpecialProperty: String, CaseIterable, Identifiable {
    case small, medium, large
    var id: String { rawValue }
}

struct Cat: Identifiable {
    let id = UUID()
    var name: String
    var size: SpecialProperty
}

@State private var sources = [
    Cat(name: "Bella", size: .small),
    Cat(name: "Max", size: .large)
]

var body: some View {
    List {
        Picker("Size for all pets", sources: $sources, selection: \.size) {
            ForEach(SpecialProperty.allCases) { size in
                Text(size.rawValue).tag(size)
            }
        }

        ForEach(sources) { pet in
            Text("\(pet.name): \(pet.size.rawValue)")
        }
    }
}