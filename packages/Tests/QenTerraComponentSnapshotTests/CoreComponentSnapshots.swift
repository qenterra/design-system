#if os(macOS)
import AppKit
import SwiftUI
import Testing
import QenTerraComponents
import QenTerraDesignTokens

@MainActor
@Suite("Native core component snapshots", .serialized)
struct CoreComponentSnapshots {
    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func controls(appearance: DesignAppearancePreference) throws {
        try assertSnapshot(name: "controls-\(appearance.rawValue)", size: CGSize(width: 660, height: 590), configuration: configuration(appearance)) {
            ControlsFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func rows(appearance: DesignAppearancePreference) throws {
        try assertSnapshot(name: "rows-\(appearance.rawValue)", size: CGSize(width: 620, height: 670), configuration: configuration(appearance)) {
            RowsFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark], [false, true])
    func settings(appearance: DesignAppearancePreference, longCopy: Bool) throws {
        try assertSnapshot(
            name: "settings-\(longCopy ? "long-copy" : "standard")-\(appearance.rawValue)",
            size: CGSize(width: 680, height: longCopy ? 710 : 590), configuration: configuration(appearance)
        ) {
            SettingsFixture(longCopy: longCopy)
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func navigation(appearance: DesignAppearancePreference) throws {
        try assertSnapshot(name: "navigation-\(appearance.rawValue)", size: CGSize(width: 560, height: 410), configuration: configuration(appearance)) {
            NavigationFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func feedback(appearance: DesignAppearancePreference) throws {
        try assertSnapshot(name: "feedback-\(appearance.rawValue)", size: CGSize(width: 960, height: 760), configuration: configuration(appearance)) {
            FeedbackFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func aboutPagesRemainProductConfigurable(appearance: DesignAppearancePreference) throws {
        try assertSnapshot(name: "about-two-products-\(appearance.rawValue)", size: CGSize(width: 720, height: 860), configuration: configuration(appearance)) {
            AboutComparisonFixture()
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func reducedMotionAndOpaqueTransparencyFallback(appearance: DesignAppearancePreference) throws {
        let regular = try NativeSnapshotHost(
            size: CGSize(width: 620, height: 370), configuration: configuration(appearance),
            accessibility: .init(reducesMotion: true)
        ) { ReducedEffectsFixture() }
        let reducedTransparency = try NativeSnapshotHost(
            size: CGSize(width: 620, height: 370), configuration: configuration(appearance),
            accessibility: .init(reducesMotion: true, reducesTransparency: true)
        ) { ReducedEffectsFixture() }
        let regularImage = try regular.render()
        let fallbackImage = try reducedTransparency.render()
        // Shipped core surfaces are already opaque. Reduced Transparency must preserve them exactly.
        #expect(regularImage == fallbackImage)
        try assertSnapshotImage(fallbackImage, name: "reduced-effects-\(appearance.rawValue)")
    }

    @Test func systemAppearanceChangesOnTheSameHost() throws {
        let observed = ObservedEnvironment()
        var contentConstructions = 0
        let configuration = configuration(.system)
        let host = try NativeSnapshotHost(size: CGSize(width: 660, height: 590), configuration: configuration) {
            let _ = { contentConstructions += 1 }()
            ControlsFixture().background(EnvironmentProbe(observed: observed))
        }
        host.setAppearance(.aqua)
        let light = try host.render()
        #expect(observed.value?.appearance == .light)
        let lightGeometry = host.view.frame
        host.setAppearance(.darkAqua)
        let dark = try host.render()
        #expect(observed.value?.appearance == .dark)
        #expect(configuration.appearance == .system)
        #expect(contentConstructions == 1)
        #expect(host.view.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua)
        #expect(host.view.frame == lightGeometry)
        #expect(light.width == dark.width && light.height == dark.height)
        #expect(light.pixels != dark.pixels)
        #expect(throws: SnapshotFailure.self) { try light.compare(dark) }
        try assertSnapshotImage(light, name: "system-live-light")
        try assertSnapshotImage(dark, name: "system-live-dark")
    }

    @Test func repeatedNativeLoadingRendersAreDeterministic() throws {
        let host = try NativeSnapshotHost(size: CGSize(width: 960, height: 760), configuration: configuration(.dark)) {
            FeedbackFixture()
        }
        let first = try host.render()
        try first.compare(host.render())
        let otherHost = try NativeSnapshotHost(size: CGSize(width: 960, height: 760), configuration: configuration(.dark)) {
            FeedbackFixture()
        }
        try first.compare(otherHost.render())
    }

    @Test func uninjectedHostsTrackLiveNativeEnvironment() throws {
        for configuration: DesignSystemConfiguration? in [nil, .init(productProfile: .cadence, density: .compact)] {
            let observed = ObservedEnvironment()
            let host = try NativeSnapshotHost(size: CGSize(width: 280, height: 300), configuration: configuration, accessibility: nil) {
                AccessibilityResolutionFixture().background(EnvironmentProbe(observed: observed))
            }
            for appearance: NSAppearance.Name in [.aqua, .darkAqua, .accessibilityHighContrastAqua] {
                host.setAppearance(appearance)
                _ = try host.render()
                let reading = try #require(observed.reading)
                #expect(reading.resolved == reading.native)
                #expect(reading.configuration == configuration ?? .init())
                #expect(reading.profile == configuration?.productProfile ?? .standard)
                #expect(reading.density == configuration?.density ?? .standard)
            }
        }
    }

    @Test func explicitAccessibilityFixturesControlShippedViews() throws {
        var images: [RGBAImage] = []
        for reduced in [false, true] {
            let observed = ObservedEnvironment()
            let host = try NativeSnapshotHost(
                size: CGSize(width: 280, height: 300), configuration: configuration(.system),
                accessibility: .init(increasedContrast: reduced, reducesMotion: reduced, reducesTransparency: reduced)
            ) {
                AccessibilityResolutionFixture().background(EnvironmentProbe(observed: observed))
            }
            host.setAppearance(.accessibilityHighContrastAqua)
            images.append(try host.render())
            let reading = try #require(observed.reading)
            #expect(reading.resolved.isIncreasedContrast == reduced)
            #expect(reading.resolved.reducesMotion == reduced)
            #expect(reading.resolved.reducesTransparency == reduced)
            #expect(nativeProgressIndicatorCount(in: host.view) == (reduced ? 0 : 2))
            print("Native High Contrast appearance probe: contrast=\(reading.native.isIncreasedContrast), motion=\(reading.native.reducesMotion), transparency=\(reading.native.reducesTransparency); explicit=\(reduced)")
        }
        #expect(images[0].width == images[1].width && images[0].height == images[1].height)
        #expect(throws: SnapshotFailure.self) { try images[0].compare(images[1]) }
    }

    @Test func increasedContrastChangesEachShippedSurfaceWithoutChangingGeometry() throws {
        let surfaces = [
            AnyView(Button("Selected") {}.buttonStyle(DesignButtonStyle(role: .secondary, state: .init(isSelected: true)))),
            AnyView(InteractiveRowSurface(state: .init(isSelected: true)) { Text("Selected row").frame(width: 220, height: 40) }),
            AnyView(CardContainer { Text("Card border").frame(width: 180, height: 24) })
        ]
        for surface in surfaces {
            let normal = try NativeSnapshotHost(size: CGSize(width: 260, height: 80), configuration: configuration(.light)) { surface.padding(8) }
            let increased = try NativeSnapshotHost(
                size: CGSize(width: 260, height: 80), configuration: configuration(.light),
                accessibility: .init(increasedContrast: true)
            ) { surface.padding(8) }
            let first = try normal.render()
            let second = try increased.render()
            #expect(normal.view.frame == increased.view.frame)
            #expect(first.width == second.width && first.height == second.height)
            #expect(throws: SnapshotFailure.self) { try first.compare(second) }
        }
    }

    @Test func liveDesignSystemConfigurationPreservesScopedKeyPrecedence() throws {
        let model = LiveConfiguration()
        let inherited = ObservedEnvironment()
        let scoped = ObservedEnvironment()
        let host = try NativeSnapshotHost(size: CGSize(width: 280, height: 100), configuration: nil, accessibility: nil) {
            LiveConfigurationProbe(model: model, inherited: inherited, scoped: scoped)
        }
        _ = try host.render()
        #expect(inherited.value?.appearance == .light)
        model.configuration = .init(productProfile: .cadence, density: .comfortable)
        host.setAppearance(.darkAqua)
        _ = try host.render()
        #expect(inherited.value?.appearance == .dark)
        #expect(inherited.value?.productProfile == .cadence)
        #expect(inherited.value?.density == .comfortable)
        #expect(scoped.reading?.configuration == model.configuration)
        #expect(scoped.value?.productProfile == .standard)
        #expect(scoped.value?.density == .compact)
        model.configuration.appearance = .light
        _ = try host.render()
        #expect(inherited.value?.appearance == .light)
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func primaryAndDestructiveStateTextRetainsContrast(appearance: DesignAppearancePreference) throws {
        for role in [DesignButtonRole.primary, .destructive] {
            for state in [DesignButtonState(isHovered: true), .init(isPressed: true), .init(isSelected: true)] {
                let image = try buttonImage(role: role, state: state, appearance: appearance)
                let contrast = maximumContentContrast(in: image)
                #expect(contrast >= 4.5, "\(role) \(state) \(appearance) text contrast: \(contrast)")
            }
        }
    }

    @Test(arguments: [DesignAppearancePreference.light, .dark])
    func primaryLoadingIndicatorRemainsVisible(appearance: DesignAppearancePreference) throws {
        let image = try buttonImage(role: .primary, state: .init(isLoading: true), appearance: appearance)
        let contrast = maximumContentContrast(in: image)
        let nativeHost = try NativeSnapshotHost(
            size: CGSize(width: 192, height: 64),
            configuration: configuration(appearance == .dark ? .light : .dark)
        ) {
            ProgressView().controlSize(.small)
                .frame(width: 192, height: 64)
                .background(Color(designToken: DesignTokens.Color.actionPrimary, appearance: appearance == .dark ? .dark : .light))
        }
        let reference = try nativeHost.render()
        let nativeContrast = maximumContentContrast(in: reference)
        #expect(image.width == reference.width && image.height == reference.height)
        #expect(nativeContrast > 1, "The native reference itself must contain a visible stroke")
        #expect(contrast >= nativeContrast, "Primary loading indicator must retain native stroke contrast in \(appearance)")
    }

    private func buttonImage(role: DesignButtonRole, state: DesignButtonState, appearance: DesignAppearancePreference) throws -> RGBAImage {
        let host = try NativeSnapshotHost(size: CGSize(width: 192, height: 64), configuration: configuration(appearance)) {
            Button {} label: { Text("Continue").frame(width: 120) }
                .buttonStyle(DesignButtonStyle(role: role, state: state))
                .frame(width: 192, height: 64)
        }
        return try host.render()
    }

    /// Samples only the button interior, excluding its rounded edge and any surrounding canvas.
    private func maximumContentContrast(in image: RGBAImage) -> Double {
        func luminance(x: Int, y: Int) -> Double {
            let offset = (y * image.width + x) * 4
            let values = (0..<3).map { channel -> Double in
                let value = Double(image.pixels[offset + channel]) / 255
                return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return values[0] * 0.2126 + values[1] * 0.7152 + values[2] * 0.0722
        }
        let background = luminance(x: 30, y: 32)
        var maximum = 1.0
        for y in 22..<42 {
            for x in 42..<150 {
                let foreground = luminance(x: x, y: y)
                maximum = max(maximum, (max(foreground, background) + 0.05) / (min(foreground, background) + 0.05))
            }
        }
        return maximum
    }

    private func configuration(_ appearance: DesignAppearancePreference) -> DesignSystemConfiguration {
        .init(appearance: appearance, productProfile: .cadence, density: .standard)
    }
}

private struct ControlsFixture: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PageHeader("Controls", subtitle: "Roles and explicit interaction states")
            HStack(spacing: 12) {
                Button("Continue") {}.buttonStyle(DesignButtonStyle(role: .primary))
                Button("Choose Folder") {}.buttonStyle(DesignButtonStyle(role: .secondary))
                Button("Cancel") {}.buttonStyle(DesignButtonStyle(role: .quiet))
                Button("Remove") {}.buttonStyle(DesignButtonStyle(role: .destructive))
            }
            HStack(spacing: 12) {
                Button {} label: { Image(systemName: "plus") }.buttonStyle(DesignButtonStyle(role: .icon))
                Button("Add to Playlist") {}.buttonStyle(RowActionButtonStyle())
                Button("Read the Guide") {}.buttonStyle(DesignButtonStyle(role: .link))
                KeycapChord(tokens: ["⌘", "K"])
            }
            DesignSeparator()
            controlRow("Hover", state: .init(isHovered: true))
            controlRow("Pressed", state: .init(isPressed: true))
            controlRow("Focused", state: .init(isFocused: true))
            controlRow("Selected", state: .init(isSelected: true))
            controlRow("Disabled", state: .init(), disabled: true)
            controlRow("Loading", state: .init(isLoading: true))
        }
        .padding(24)
    }

    private func controlRow(_ label: String, state: DesignButtonState, disabled: Bool = false) -> some View {
        HStack(spacing: 16) {
            Text(label).frame(width: 100, alignment: .leading)
                .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
            Button("Continue") {}.buttonStyle(DesignButtonStyle(role: .primary, state: state)).disabled(disabled)
            Button("Choose Folder") {}.buttonStyle(DesignButtonStyle(role: .secondary, state: state)).disabled(disabled)
            Button("Remove") {}.buttonStyle(DesignButtonStyle(role: .destructive, state: state)).disabled(disabled)
        }
    }
}

private struct RowsFixture: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PageHeader("Interactive rows", subtitle: "Stable geometry across the complete state matrix")
                .padding(.bottom, 8)
            row("Default", state: .init())
            row("Hover", state: .init(isHovered: true))
            row("Pressed", state: .init(isPressed: true))
            row("Focused", state: .init(isFocused: true))
            row("Selected", state: .init(isSelected: true))
            row("Disabled", state: .init(isDisabled: true))
            row("Loading", state: .init(isLoading: true))
            row("Unavailable", state: .init(isUnavailable: true))
            row("Increased contrast", state: .init(isFocused: true, isSelected: true, isIncreasedContrast: true))
        }
        .padding(24)
    }

    private func row(_ title: String, state: InteractiveRowState) -> some View {
        HStack(spacing: 16) {
            Text(title).font(.callout).frame(width: 132, alignment: .leading)
                .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
            InteractiveRowSurface(state: state) {
                HStack(spacing: 12) {
                    Image(systemName: "folder")
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Evening collection").font(.body.weight(.medium))
                        Text("12 items · Local files").font(.caption)
                            .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption)
                }
                .padding(.horizontal, 12)
                .frame(height: 48)
            }
        }
    }
}

private struct SettingsFixture: View {
    let longCopy: Bool

    var body: some View {
        PageScrollView {
            PageHeader("Settings", subtitle: longCopy ? "Expanded descriptions and localized labels" : "Appearance and library preferences")
            SettingsSection("Appearance") {
                SettingsRow(
                    longCopy ? "Application appearance and system preference" : "Appearance",
                    description: longCopy
                        ? "Follow the appearance selected in System Settings. Changes apply while the application remains open and preserve your current position and selection."
                        : "Follow System Settings or choose a fixed appearance."
                ) {
                    Picker("Appearance", selection: .constant("System")) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }.labelsHidden().frame(width: 140)
                }
                DesignSeparator()
                SettingsToggleRow(
                    longCopy ? "Show album artwork beside each item in the local library" : "Show artwork",
                    isOn: .constant(true)
                )
                DesignSeparator()
                SettingsToggleRow("Reduce visual distractions", isOn: .constant(false))
            }
            SettingsSection("Library") {
                SettingsRow(
                    longCopy ? "Location of the folder containing your local music collection" : "Music folder",
                    description: longCopy
                        ? "Choose a folder you can access on this Mac. Existing files stay in their original location; changing this setting does not move or remove your music."
                        : "Files stay in their original location."
                ) {
                    Button("Choose Folder") {}.buttonStyle(DesignButtonStyle(role: .secondary))
                }
                DesignSeparator()
                SettingsRow("Automatic updates", description: "Updates are managed by your organization.") {
                    Toggle("Automatic updates", isOn: .constant(false)).labelsHidden().disabled(true)
                }
            }
        }
    }
}

private struct NavigationFixture: View {
    private let items: [NavigationRailItem<String>] = [
        .init(id: "library", title: "Library", symbol: "square.stack", badge: "24"),
        .init(id: "favorites", title: "Favorites", symbol: "heart"),
        .init(id: "playlists", title: "Playlists", symbol: "music.note.list", badge: "3"),
        .init(id: "downloads", title: "Downloads", symbol: "arrow.down.circle", isEnabled: false),
        .init(id: "settings", title: "Settings", symbol: "gearshape")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageHeader("Navigation rail", subtitle: "Compact and expanded presentation")
            HStack(alignment: .top, spacing: 32) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Compact").font(.caption)
                    NavigationRail(items: items, selection: .constant("library"), isCompact: true)
                }
                DesignSeparator(orientation: .vertical)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Expanded").font(.caption)
                    NavigationRail(items: items, selection: .constant("library"))
                }
                .frame(width: 270)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
    }
}

@MainActor
private struct FeedbackFixture: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PageHeader("Content and operation feedback", subtitle: "Synthetic states with concrete next actions")
            Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow {
                    feedbackCell("Empty") {
                        ContentStateView(state: .empty(title: "Your library is empty", message: "Add a folder to see your music here."))
                    }
                    feedbackCell("No results") {
                        ContentStateView(state: .noResults(title: "No matching items", message: "Try another name or clear the filters."))
                    }
                    feedbackCell("Loading") {
                        ContentStateView(state: .loading(title: "Reading library…"))
                    }
                }
                GridRow {
                    feedbackCell("Error") {
                        ContentStateView(state: .error(title: "Folder cannot be read", message: "The selected folder is no longer available."))
                    }
                    feedbackCell("Recovery") {
                        ContentStateView(
                            state: .error(title: "Connection interrupted", message: "Check the connection, then try again."),
                            recovery: PresentationAction(title: "Try Again", handler: {})
                        )!
                    }
                    feedbackCell("Unavailable") {
                        ContentStateView(state: .unavailable(title: "Drive is disconnected", message: "Reconnect the drive to access these files."))
                    }
                }
            }
            OperationStateView(state: .inProgress(
                title: "Importing files", message: "6 of 12 files processed",
                progress: MeasuredOperationProgress(completedUnitCount: 6, totalUnitCount: 12)!
            ))
            StatusBanner(
                configuration: .init(id: "restored", tone: .success, title: "Connection restored", message: "Your library is available again."),
                dismiss: PresentationAction(title: "Dismiss", handler: {})
            )
        }
        .padding(24)
    }

    private func feedbackCell<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(.caption.weight(.medium)).padding([.top, .leading], 12)
                .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
            content().frame(maxHeight: .infinity)
        }
        .frame(width: 293, height: 220)
        .background(Color(designToken: DesignTokens.Color.surfaceSecondary))
    }
}

private struct ReducedEffectsFixture: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageHeader("Reduced effects", subtitle: "Static loading indicators and opaque core surfaces")
            HStack(spacing: 16) {
                Button("Loading library") {}.buttonStyle(DesignButtonStyle(role: .primary, state: .init(isLoading: true)))
                Button("Loading folder") {}.buttonStyle(DesignButtonStyle(role: .secondary, state: .init(isLoading: true)))
            }
            InteractiveRowSurface(state: .init(isLoading: true)) {
                Text("Library content is loading").frame(maxWidth: .infinity).frame(height: 48)
            }
            CardContainer {
                SettingsRow("Opaque surface", description: "This core component uses a solid semantic background.") {
                    Image(systemName: "checkmark.circle")
                }
            }
        }
        .padding(24)
    }
}

private struct AboutComparisonFixture: View {
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            AboutPage(configuration: Self.cadence) { productIcon("music.note") }
            DesignSeparator(orientation: .vertical)
            AboutPage(configuration: Self.example) { productIcon("play.square.stack") }
        }
    }

    private func productIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 44, weight: .medium))
            .frame(width: 96, height: 96)
            .background(Color(designToken: DesignTokens.Color.surfaceRaised))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.hero))
    }

    private static let cadence = AboutPageConfiguration(
        applicationName: "Cadence", tagline: "Your music, in its own rhythm.",
        description: "A native music library for local files. Browse albums, build playlists, and listen without moving your collection.",
        versionText: "Version 1.0 (100)", creatorText: "Created by QenTerra",
        copyrightText: "© 2026 QenTerra", resourcesTitle: "Resources",
        resources: [
            resource("website", "Website", "Learn more about Cadence", "globe", "https://example.com/cadence"),
            resource("guide", "User Guide", "Read the library and playback guide", "book", "https://example.com/cadence/guide"),
            resource("support", "Support", "Get help with your local library", "questionmark.circle", "mailto:support@example.com")
        ]
    )

    private static let example = AboutPageConfiguration(
        applicationName: "Example Player", tagline: "A second product, with a different purpose.",
        description: "Review recordings and organize reference sessions. This longer description verifies that product-provided content wraps without losing the resource controls below it.",
        versionText: "Release 9.4 · Build 72", creatorText: "Designed by Example Studio",
        copyrightText: "© 2026 Example Studio", resourcesTitle: "Project links",
        resources: [
            resource("source", "Source Code", "Browse the example project", "chevron.left.forwardslash.chevron.right", "https://example.org/source"),
            resource("notes", "Release Notes", "See what changed in this release", "doc.text", "https://example.org/releases"),
            AboutResource(id: "community", title: "Community", subtitle: "Community access is temporarily unavailable", symbol: "person.2", destination: URL(string: "https://example.org/community")!, accessibilityHint: "Opens in the default browser", availability: .unavailable(accessibilityValue: "Temporarily unavailable"))
        ]
    )

    private static func resource(_ id: String, _ title: String, _ subtitle: String, _ symbol: String, _ url: String) -> AboutResource {
        AboutResource(id: id, title: title, subtitle: subtitle, symbol: symbol, destination: URL(string: url)!, accessibilityHint: "Opens the supplied destination")
    }
}

@MainActor
private final class ObservedEnvironment {
    var reading: EnvironmentReading?
    var value: DesignNativeEnvironment? { reading?.resolved }
}

private struct EnvironmentReading: Equatable {
    let resolved: DesignNativeEnvironment
    let native: DesignNativeEnvironment
    let configuration: DesignSystemConfiguration
    let profile: DesignProductProfile
    let density: DesignDensity
}

private struct NativeEnvironmentPreference: PreferenceKey {
    static let defaultValue: EnvironmentReading? = nil
    static func reduce(value: inout EnvironmentReading?, nextValue: () -> EnvironmentReading?) {
        value = nextValue() ?? value
    }
}

private struct EnvironmentProbe: View {
    @Environment(\.designNativeEnvironment) private var environment
    @Environment(\.designSystemConfiguration) private var configuration
    @Environment(\.designProductProfile) private var profile
    @Environment(\.designDensity) private var density
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var motion
    @Environment(\.accessibilityReduceTransparency) private var transparency
    let observed: ObservedEnvironment

    var body: some View {
        Color.clear.preference(key: NativeEnvironmentPreference.self, value: EnvironmentReading(
            resolved: environment,
            native: DesignNativeEnvironment(
                appearance: colorScheme == .dark ? .dark : .light,
                productProfile: profile, density: density, isIncreasedContrast: contrast == .increased,
                reducesMotion: motion, reducesTransparency: transparency
            ),
            configuration: configuration, profile: profile, density: density
        ))
            .onPreferenceChange(NativeEnvironmentPreference.self) { value in
                observed.reading = value
            }
    }
}

private struct AccessibilityResolutionFixture: View {
    var body: some View {
        VStack(spacing: 12) {
            Button("Loading") {}.buttonStyle(DesignButtonStyle(role: .secondary, state: .init(isLoading: true)))
            InteractiveRowSurface(state: .init(isLoading: true)) { Text("Loading row").frame(width: 240, height: 40) }
            Button("Selected") {}.buttonStyle(DesignButtonStyle(role: .secondary, state: .init(isSelected: true)))
            InteractiveRowSurface(state: .init(isSelected: true)) { Text("Selected row").frame(width: 240, height: 40) }
            CardContainer { Text("Card border") }
        }
        .padding(12)
    }
}

@MainActor
private final class LiveConfiguration: ObservableObject {
    @Published var configuration = DesignSystemConfiguration()
}

private struct LiveConfigurationProbe: View {
    @ObservedObject var model: LiveConfiguration
    let inherited: ObservedEnvironment
    let scoped: ObservedEnvironment

    var body: some View {
        VStack {
            EnvironmentProbe(observed: inherited)
            EnvironmentProbe(observed: scoped)
                .environment(\.designProductProfile, .standard)
                .environment(\.designDensity, .compact)
        }
        .designSystem(model.configuration)
    }
}

@MainActor
private func nativeProgressIndicatorCount(in view: NSView) -> Int {
    (view is NSProgressIndicator ? 1 : 0) + view.subviews.reduce(0) { $0 + nativeProgressIndicatorCount(in: $1) }
}
#endif
