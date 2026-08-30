struct Cat: Identifiable {
    let id = UUID()
    var name: String
    var isHungry: Bool
}

@State private var sources = [
    Cat(name: "Bella", isHungry: false),
    Cat(name: "Max", isHungry: true)
]

var body: some View {
    List {
        Toggle("Foo1", sources: $sources, isOn: \.isHungry)
        ForEach(sources) { pet in
            Text("\(pet.name): \(pet.isHungry ? "😾" : "😻")")
        }
    }
}