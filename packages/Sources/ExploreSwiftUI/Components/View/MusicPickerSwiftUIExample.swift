import MusicKit

@State var showMusicPicker = true
@State var selectedSongs: MusicItemCollection<Song> = []

var body: some View {
    Text("Foo")
        .musicPicker(
            isPresented: $showMusicPicker,
            title: Text("Bar"),
            selection: $selectedSongs
        )
    }