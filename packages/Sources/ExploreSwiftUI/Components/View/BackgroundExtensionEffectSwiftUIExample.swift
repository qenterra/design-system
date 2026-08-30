NavigationSplitView {
} detail: {
    ZStack {
        VStack(spacing: 0) {
            Image(.cats)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .frame(maxHeight: .infinity)

            Image(.cats)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .backgroundExtensionEffect()
                .frame(maxHeight: .infinity)
        }
    }
}