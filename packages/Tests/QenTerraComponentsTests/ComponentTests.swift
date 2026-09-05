import Testing
import Foundation
import QenTerraComponents
import QenTerraDesignTokens
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(AppKit)
import AppKit
#endif

@Test func componentModuleKeepsExistingPublicPrimitives() {
    _ = PrimaryButtonStyle()
    _ = GroupContainer()
    _ = InteractiveRowSurface(state: InteractiveRowState()) {
        EmptyView()
    }
}

@Test func interactiveRowPrioritisesUnavailableThenFocusThenSelection() {
    let unavailable = InteractiveRowState(
        isFocused: true,
        isSelected: true,
        isUnavailable: true
    )
    #expect(unavailable.fill == DesignTokens.Color.fillDisabled)
    #expect(unavailable.border == nil)

    let focused = InteractiveRowState(isFocused: true, isSelected: true)
    #expect(focused.border == DesignTokens.Color.borderFocus)
}

@Test func buttonRolesAndSettingsCompositionsRemainPublic() {
    for role in DesignButtonRole.allCases {
        _ = DesignButtonStyle(role: role)
    }

    _ = IconActionButton(
        designIcon: .add,
        accessibilityLabel: "Add item",
        help: "Create a new item",
        isEnabled: false,
        action: {}
    )
    _ = RowActionButtonStyle()
    _ = CardContainer {
        Text("Card content")
    }
    _ = SettingsSection("Playback") {
        Text("Settings content")
    }
    _ = SettingsRow("Output", description: "Choose the device used for audio output.") {
        Toggle("Enable output", isOn: .constant(true))
    }
    _ = SettingsToggleRow("Show artwork", isOn: .constant(true))
}

@Test func loadingComponentsSupportNativeAccessibilityEnvironments() {
    _ = Button("Synchronize") {}
        .buttonStyle(DesignButtonStyle(role: .primary, state: .init(isLoading: true)))

    _ = InteractiveRowSurface(state: .init(isLoading: true)) {
        Text("Synchronize")
    }
}

@Test func splitLayoutClampsWithoutLosingTotalWidth() {
    let result = ResizableSplitLayout.resolve(
        availableWidth: 900,
        proposedLeadingWidth: 700,
        minimumLeadingWidth: 240,
        minimumTrailingWidth: 360,
        separatorWidth: 1
    )

    #expect(result.leadingWidth == 539)
    #expect(result.trailingWidth == 360)
}

@Test func componentMetricsResolveTheLiveProfileAndDensity() {
    let cadence = DesignComponentMetrics.resolve(
        for: nativeEnvironment(profile: .cadence, density: .compact)
    )
    let standard = DesignComponentMetrics.resolve(
        for: nativeEnvironment(profile: .standard, density: .standard)
    )
    let comfortable = DesignComponentMetrics.resolve(
        for: nativeEnvironment(profile: .standard, density: .comfortable)
    )

    #expect(cadence.pageInset == DesignProductMetrics.cadence.pageInset)
    #expect(standard.pageInset == DesignTokens.Space.value6)
    #expect(comfortable.pageInset == DesignTokens.Space.value8)
    #expect(standard.rowHeight == DesignTokens.Size.rowStandard)
    #expect(comfortable.rowHeight == DesignTokens.Size.rowComfortable)
}

@Test func splitLayoutNormalizesTheDividerAcrossResolutionAndInteraction() {
    let negative = ResizableSplitLayout.resolve(
        availableWidth: 900,
        proposedLeadingWidth: 700,
        minimumLeadingWidth: 240,
        minimumTrailingWidth: 360,
        separatorWidth: -10
    )
    let zero = ResizableSplitLayout.resolve(
        availableWidth: 0,
        proposedLeadingWidth: 700,
        minimumLeadingWidth: 240,
        minimumTrailingWidth: 360,
        separatorWidth: 0
    )
    let overconstrained = ResizableSplitLayout.resolve(
        availableWidth: 100,
        proposedLeadingWidth: 90,
        minimumLeadingWidth: 240,
        minimumTrailingWidth: 360,
        separatorWidth: 1
    )

    #expect(negative.separatorWidth == DesignTokens.Stroke.hairline)
    #expect(negative.leadingWidth + negative.separatorWidth + negative.trailingWidth == 900)
    #expect(zero.leadingWidth == 0)
    #expect(zero.trailingWidth == 0)
    #expect(overconstrained.leadingWidth + overconstrained.trailingWidth + overconstrained.separatorWidth == 100)
    #expect(ResizableSplitLayout.pointerTargetWidth(for: -10) == DesignTokens.Size.targetPointer)
    #expect(
        ResizableSplitLayout.adjustedLeadingWidth(
            currentLeadingWidth: 320,
            direction: .increment,
            step: 10,
            availableWidth: 900,
            minimumLeadingWidth: 240,
            minimumTrailingWidth: 360,
            separatorWidth: 1
        ) == 330
    )
}

@Test func flowLayoutPortsCadenceWrappingAndProposalSemantics() {
    let narrow = DesignFlowLayout.arrangement(
        sizes: [CGSize(width: 40, height: 10), CGSize(width: 40, height: 12)],
        proposalWidth: 70,
        horizontalSpacing: 8,
        verticalSpacing: 6
    )
    let wide = DesignFlowLayout.arrangement(
        sizes: [CGSize(width: 40, height: 10), CGSize(width: 40, height: 12)],
        proposalWidth: 100,
        horizontalSpacing: 8,
        verticalSpacing: 6
    )
    let unspecified = DesignFlowLayout.arrangement(
        sizes: [CGSize(width: 40, height: 10), CGSize(width: 40, height: 12)],
        proposalWidth: nil,
        horizontalSpacing: 8,
        verticalSpacing: 6
    )

    #expect(narrow.size == CGSize(width: 40, height: 28))
    #expect(narrow.origins == [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 16)])
    #expect(wide.size == CGSize(width: 88, height: 12))
    #expect(wide.origins == [CGPoint(x: 0, y: 0), CGPoint(x: 48, y: 0)])
    #expect(unspecified.size == wide.size)
}

@Test func disabledTabsPreserveConsumerOwnedSelection() {
    let disabled = TabItem(id: "albums", title: "Albums", symbol: "square.stack", isEnabled: false)
    let enabled = TabItem(id: "songs", title: "Songs", symbol: "music.note")

    #expect(disabled.isEnabled == false)
    #expect(enabled.isEnabled == true)
    #expect(TabStrip<String>.selectionAfterActivating(disabled, current: "songs") == "songs")
    #expect(TabStrip<String>.selectionAfterActivating(enabled, current: "albums") == "songs")
}

@Test func sortMenuReportsSelectionAndRefusesDisabledFieldMutations() {
    let title = SortMenuField(id: "title", title: "Track title")
    let date = SortMenuField(id: "date", title: "Date added", isEnabled: false)
    let labels = SortMenuLabels(
        trigger: "Sort catalogue",
        field: "Field",
        order: "Direction",
        ascending: "Oldest first",
        descending: "Newest first",
        unavailable: "Sorting is unavailable"
    )
    let presentation = SortMenu<String>.presentation(
        fields: [title, date],
        selection: "title",
        order: .descending,
        labels: labels
    )

    guard case let .ready(ready) = presentation else {
        Issue.record("expected a ready sort menu presentation")
        return
    }
    #expect(ready.triggerTitle == "Sort catalogue: Track title, Newest first")
    #expect(ready.accessibilityValue == "Track title, Newest first")
    #expect(ready.selectedFieldID == "title")
    #expect(SortMenu<String>.selectionAfterActivating(date, current: "title") == "title")
    #expect(SortMenu<String>.selectionAfterActivating(title, current: "date") == "title")
}

@Test func sortMenuFailsClosedForEmptyFieldsAndStaleSelection() {
    let labels = sortMenuLabels()
    let title = SortMenuField(id: "title", title: "Track title")

    #expect(
        SortMenu<String>.presentation(
            fields: [],
            selection: "title",
            order: .ascending,
            labels: labels
        ) == .unavailable(.emptyFields)
    )
    #expect(
        SortMenu<String>.presentation(
            fields: [title],
            selection: "missing",
            order: .ascending,
            labels: labels
        ) == .unavailable(.selectionNotFound)
    )
}

@Test @MainActor func sortMenuSelectionBindingKeepsDisabledHostStateStable() {
    let title = SortMenuField(id: "title", title: "Track title")
    let date = SortMenuField(id: "date", title: "Date added", isEnabled: false)
    let artist = SortMenuField(id: "artist", title: "Artist")
    let box = SortMenuSelectionBox(value: "title")
    let binding = SortMenu<String>.selectionBinding(
        fields: [title, date, artist],
        selection: Binding(
            get: { box.value },
            set: { box.value = $0 }
        )
    )

    binding.wrappedValue = "date"
    #expect(box.value == "title")
    binding.wrappedValue = "artist"
    #expect(box.value == "artist")
}

@Test func renameAlertConfigurationPublishesSemanticValidationColor() {
    let valid = RenameAlertConfiguration(
        title: "Rename",
        fieldLabel: "Name",
        initialText: "Morning run",
        validation: .valid,
        confirmLabel: "Rename",
        cancelLabel: "Cancel"
    )
    let invalid = RenameAlertConfiguration(
        title: "Rename",
        fieldLabel: "Name",
        initialText: "",
        validation: .invalid(message: "Required"),
        confirmLabel: "Rename",
        cancelLabel: "Cancel"
    )

    #expect(valid.validationColor == DesignTokens.Color.textSecondary)
    #expect(invalid.validationColor == DesignTokens.Color.stateDestructive)
}

@Test func pageScrollPresentationMakesOwnershipObservable() {
    #expect(PageScrollView<EmptyView>.presentation(for: .component) == .componentScrollContainer)
    #expect(PageScrollView<EmptyView>.presentation(for: .consumer) == .consumerContent)
}

@Test func navigationRailPresentationKeepsIconFocusAndSelectionIndependent() {
    let enabled = NavigationRailItem(id: "library", title: "Library", symbol: "music.note")
    let disabled = NavigationRailItem(
        id: "queue",
        title: "Queue",
        symbol: "text.line.first.and.arrowtriangle.forward",
        isEnabled: false
    )
    let compact = NavigationRail<String>.presentation(
        for: enabled,
        selection: "library",
        focusedID: "queue",
        isCompact: true
    )
    let expanded = NavigationRail<String>.presentation(
        for: enabled,
        selection: "library",
        focusedID: "queue",
        isCompact: false
    )

    #expect(compact.iconAnchorWidth == expanded.iconAnchorWidth)
    #expect(compact.showsLabel == false)
    #expect(expanded.showsLabel == true)
    #expect(compact.isSelected == true)
    #expect(compact.isFocused == false)
    #expect(NavigationRail<String>.selectionAfterActivating(disabled, current: "library") == "library")
}

@Test func keycapChordPresentationCombinesExplicitTokensForAccessibility() {
    let presentation = KeycapChord.presentation(tokens: ["⌘", "R"])

    #expect(presentation.tokens == ["⌘", "R"])
    #expect(presentation.accessibilityLabel == "⌘ R")
}

@Test func contentPresentationStatesKeepEmptyAndNoResultsDistinct() {
    let empty = ContentPresentationState.empty(
        title: "Nothing here yet",
        message: "Add an item to begin."
    )
    let noResults = ContentPresentationState.noResults(
        title: "No matches",
        message: "Try another query."
    )

    #expect(empty != noResults)
}

@Test @MainActor func contentStateRejectsRecoveryForEveryNonErrorState() {
    let recovery = PresentationAction(title: "Try again") {}
    let states: [ContentPresentationState] = [
        .loading(title: "Loading library"),
        .empty(title: "Nothing here yet", message: "Add an item to begin."),
        .noResults(title: "No matches", message: "Try another query."),
        .unavailable(title: "Library unavailable", message: "Try later."),
    ]

    for state in states {
        #expect(ContentStateView(state: state, recovery: recovery) == nil)
    }
    #expect(
        ContentStateView(
            state: .error(title: "Could not load", message: "Check your connection."),
            recovery: recovery
        ) != nil
    )
}

@Test func statusBannerConfigurationHasNoPlacementScope() {
    let configuration = StatusBannerConfiguration(
        id: "library-warning",
        tone: .warning,
        title: "Library needs attention",
        message: "One source is unavailable."
    )

    #expect(configuration.id == "library-warning")
    #expect(configuration.tone == .warning)
    #expect(configuration.title == "Library needs attention")
}

@Test func operationPresentationUsesMeasuredProgressWithoutIndependentAccessibilityCopy() throws {
    let progress = try #require(
        MeasuredOperationProgress(
            completedUnitCount: 3,
            totalUnitCount: 8
        )
    )
    let state = OperationPresentationState.inProgress(
        title: "Importing tracks",
        message: "Reading metadata",
        progress: progress
    )

    #expect(state.fractionCompleted == 0.375)
    #expect(progress.fractionCompleted == 0.375)
}

@Test func measuredOperationProgressRejectsInvalidCountsAndMakesMismatchUnrepresentable() {
    #expect(MeasuredOperationProgress(completedUnitCount: 0, totalUnitCount: 0) == nil)
    #expect(MeasuredOperationProgress(completedUnitCount: -1, totalUnitCount: 8) == nil)
    #expect(MeasuredOperationProgress(completedUnitCount: 9, totalUnitCount: 8) == nil)

    let progress = MeasuredOperationProgress(
        completedUnitCount: 3,
        totalUnitCount: 8
    )
    #expect(progress?.fractionCompleted == 0.375)
}

@Test func dropZonePresentationMakesStateAndAccessibilityObservable() {
    let ready = DropZoneState.ready(accessibilityValue: "Ready to receive audio files")
    let targeted = DropZoneState.targeted(accessibilityValue: "Files are targeted")
    let unavailable = DropZoneState.unavailable(accessibilityValue: "File import is unavailable")

    #expect(ready.presentation.isEnabled == true)
    #expect(ready.presentation.isTargeted == false)
    #expect(targeted.presentation.isEnabled == true)
    #expect(targeted.presentation.isTargeted == true)
    #expect(unavailable.presentation.isEnabled == false)
    #expect(unavailable.presentation.accessibilityValue == "File import is unavailable")
}

@Test func recoveryAndDismissActionsKeepTitlesAndCallbacksTogether() {
    let recovery = PresentationAction(title: "Try again") {}
    let dismiss = PresentationAction(title: "Dismiss") {}

    #expect(recovery.title == "Try again")
    #expect(dismiss.title == "Dismiss")
}

@Test func aboutConfigurationContainsNoImplicitCadenceFallbacks() throws {
    let resource = AboutResource(
        id: "source",
        title: "Source Code",
        subtitle: "Browse the example project",
        symbol: "chevron.left.forwardslash.chevron.right",
        destination: try #require(URL(string: "https://example.com/source")),
        accessibilityHint: "Opens in the default browser",
        availability: .available
    )
    let configuration = AboutPageConfiguration(
        applicationName: "Example Player",
        tagline: "A second product.",
        description: "Different copy proves the shared page is configurable.",
        versionText: "Version 9.4 (72)",
        creatorText: "Created by Example Studio",
        copyrightText: "© 2026 Example Studio",
        resourcesTitle: "Resources",
        resources: [resource]
    )

    #expect(configuration.applicationName == "Example Player")
    #expect(configuration.versionText == "Version 9.4 (72)")
    #expect(configuration.creatorText == "Created by Example Studio")
    #expect(configuration.resources == [resource])
    #expect(configuration.resources.map(\.destination.absoluteString) == ["https://example.com/source"])
}

@Test @MainActor func constructingFeedbackViewsDoesNotInvokeConsumerCallbacks() {
    let count = CallbackCount()
    let action = PresentationAction(title: "Try again") {
        count.value += 1
    }

    _ = ContentStateView(
        state: .error(title: "Could not load", message: "Check your connection."),
        recovery: action
    )
    _ = StatusBanner(
        configuration: .init(id: "sync", tone: .informative, title: "Syncing"),
        action: action,
        dismiss: action
    )

    #expect(count.value == 0)
    action.perform()
    #expect(count.value == 1)
}

@Test @MainActor func feedbackAndAboutPublicViewsCompileWithConsumerOwnedActions() throws {
    let progress = try #require(
        MeasuredOperationProgress(
            completedUnitCount: 3,
            totalUnitCount: 8
        )
    )
    _ = ContentStateView(
        state: .empty(title: "Nothing here yet", message: "Add an item to begin.")
    )
    _ = StatusBanner(
        configuration: .init(id: "sync", tone: .informative, title: "Syncing"),
        dismiss: PresentationAction(title: "Dismiss") {}
    )
    _ = DropZone(
        state: .ready(accessibilityValue: "Ready to receive audio files"),
        title: "Drop files here",
        message: "Supported files will be reviewed before import."
    )
    _ = OperationStateView(
        state: .inProgress(title: "Importing tracks", message: "Reading metadata", progress: progress)
    )
    _ = AboutPage(configuration: exampleAboutConfiguration()) {
        Image(systemName: "music.note")
    }
    _ = AboutResourceRow(resource: exampleAboutConfiguration().resources[0], onOpenRejected: { _ in })
}

#if canImport(AppKit)
@Test @MainActor func hostedFeedbackViewsCompileWithObservableProductionPresentations() {
    _ = hostedView(
        DropZone(
            state: .targeted(accessibilityValue: "Files are targeted"),
            title: "Drop files here",
            message: "Supported files will be reviewed before import."
        )
    )
    _ = hostedView(
        DropZone(
            state: .unavailable(accessibilityValue: "File import is unavailable"),
            title: "Drop files here",
            message: "Supported files will be reviewed before import."
        )
    )

    #expect(DropZoneState.targeted(accessibilityValue: "Files are targeted").presentation.isTargeted)
    #expect(DropZoneState.unavailable(accessibilityValue: "File import is unavailable").presentation.isEnabled == false)
}

@Test @MainActor func aboutPageUsesItsProductionAccessibilityPresentation() {
    let configuration = exampleAboutConfiguration()
    _ = hostedView(
        AboutPage(configuration: configuration) {
            Image(systemName: "music.note")
        }
    )
    let presentation = AboutPage<Image>.init(configuration: configuration) {
        Image(systemName: "music.note")
    }.accessibilityPresentation

    #expect(presentation.applicationName == "Example Player")
    #expect(presentation.versionText == "Version 9.4 (72)")
    #expect(presentation.creatorText == "Created by Example Studio")
    #expect(presentation.resources == [
        .init(resource: configuration.resources[0]),
    ])
    #expect(presentation.value.contains("https://example.com/source"))
    #expect(presentation.value.localizedCaseInsensitiveContains("cadence") == false)
}

@Test @MainActor func aboutResourceRowUsesInjectedOpenURLAndReportsDiscardedResults() {
    let resource = exampleAboutConfiguration().resources[0]
    let accepted = URLActionRecorder()
    let acceptedRow = AboutResourceRow(
        resource: resource,
        openURLAction: OpenURLAction { url in
            accepted.destinations.append(url)
            return .handled
        },
        onOpenRejected: { _ in accepted.rejections += 1 }
    )
    acceptedRow.activate()
    #expect(accepted.destinations == [resource.destination])
    #expect(accepted.rejections == 0)

    let rejected = URLActionRecorder()
    let rejectedRow = AboutResourceRow(
        resource: resource,
        openURLAction: OpenURLAction { _ in .discarded },
        onOpenRejected: { result in
            if case .discarded = result {
                rejected.rejections += 1
            }
        }
    )
    rejectedRow.activate()
    #expect(rejected.rejections == 1)
}

@Test @MainActor func unavailableAboutResourceIsDisabledAndExposesConsumerValue() throws {
    let resource = AboutResource(
        id: "unavailable",
        title: "Source Code",
        subtitle: "Browse the example project",
        symbol: "chevron.left.forwardslash.chevron.right",
        destination: try #require(URL(string: "https://example.com/source")),
        accessibilityHint: "Opens in the default browser",
        availability: .unavailable(accessibilityValue: "Source Code is unavailable")
    )
    let row = AboutResourceRow(resource: resource, onOpenRejected: { _ in })

    #expect(row.presentation.accessibilityValue == "Source Code is unavailable")
    #expect(row.presentation.isEnabled == false)
}
#endif

#if canImport(AppKit)
@MainActor
private final class URLActionRecorder {
    var destinations: [URL] = []
    var rejections = 0
}

@MainActor
private func hostedView<Content: View>(_ content: Content) -> NSHostingView<Content> {
    let host = NSHostingView(rootView: content)
    host.frame = NSRect(x: 0, y: 0, width: 720, height: 860)
    host.layoutSubtreeIfNeeded()
    return host
}
#endif

private func exampleAboutConfiguration() -> AboutPageConfiguration {
    AboutPageConfiguration(
        applicationName: "Example Player",
        tagline: "A second product.",
        description: "Different copy proves the shared page is configurable.",
        versionText: "Version 9.4 (72)",
        creatorText: "Created by Example Studio",
        copyrightText: "© 2026 Example Studio",
        resourcesTitle: "Resources",
        resources: [
            AboutResource(
                id: "source",
                title: "Source Code",
                subtitle: "Browse the example project",
                symbol: "chevron.left.forwardslash.chevron.right",
                destination: URL(string: "https://example.com/source")!,
                accessibilityHint: "Opens in the default browser"
            )
        ]
    )
}

private func nativeEnvironment(
    profile: DesignProductProfile,
    density: DesignDensity
) -> DesignNativeEnvironment {
    DesignNativeEnvironment(
        appearance: .light,
        productProfile: profile,
        density: density,
        isIncreasedContrast: false,
        reducesMotion: false,
        reducesTransparency: false
    )
}

private func sortMenuLabels() -> SortMenuLabels {
    SortMenuLabels(
        trigger: "Sort catalogue",
        field: "Field",
        order: "Direction",
        ascending: "Oldest first",
        descending: "Newest first",
        unavailable: "Sorting is unavailable"
    )
}

@MainActor
private final class SortMenuSelectionBox {
    var value: String

    init(value: String) {
        self.value = value
    }
}

@MainActor
private final class CallbackCount {
    var value = 0
}

@Test func layoutNavigationAndOverlayPrimitivesExposeConsumerOwnedAPIs() {
    _ = PageHeader("Library", subtitle: "All music") {
        Button("Add") {}
    }
    _ = PageScrollView(ownership: .consumer, sectionSpacing: 32) {
        Text("Consumer owns this scroll view")
    }
    _ = DesignFlowLayout() {
        Text("One")
        Text("Two")
    }
    _ = ResizableSplitView(
        leadingWidth: .constant(320),
        minimumLeadingWidth: 240,
        minimumTrailingWidth: 360
    ) {
        Text("Leading")
    } trailing: {
        Text("Trailing")
    }
    _ = DesignSeparator()
    _ = WorkspacePaneHeader("Queue") {
        Button("Clear") {}
    }

    let railItem = NavigationRailItem(
        id: "library",
        title: "Library",
        symbol: "music.note",
        badge: "3"
    )
    #expect(railItem.id == "library")
    _ = NavigationRail(
        items: [railItem],
        selection: .constant("library"),
        isCompact: true
    )

    let tabItem = TabItem(id: "songs", title: "Songs", symbol: "music.note.list")
    #expect(tabItem.id == "songs")
    _ = TabStrip(items: [tabItem], selection: .constant("songs"))

    let sortField = SortMenuField(id: "title", title: "Title")
    _ = SortMenu(
        fields: [sortField],
        selection: .constant("title"),
        order: .constant(.ascending),
        labels: sortMenuLabels()
    )
    let rename = RenameAlertConfiguration(
        title: "Rename playlist",
        message: "Use a distinct name.",
        fieldLabel: "Name",
        initialText: "Morning run",
        validation: .valid,
        confirmLabel: "Rename",
        cancelLabel: "Cancel"
    )
    #expect(rename.initialText == "Morning run")
    _ = Keycap("⌘")
    _ = KeycapChord(tokens: ["⌘", "R"])
}
