#if os(macOS)
import AppKit
import QenTerraDesignTokens

public struct MediaTableRowPresentation<ID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: ID
    public let title: String
    public let creator: String
    public let collection: String
    public let year: String
    public let duration: String
    public let isExplicit: Bool
    public let isFavorite: Bool
    public let isCurrent: Bool
    public let isPlaying: Bool
    public let isAvailable: Bool
    public let artworkIdentity: String?
    public let favoriteAccessibilityLabel: String?
    public let actionsAccessibilityLabel: String?

    public init(
        id: ID,
        title: String,
        creator: String,
        collection: String,
        year: String,
        duration: String,
        isExplicit: Bool,
        isFavorite: Bool,
        isCurrent: Bool,
        isPlaying: Bool,
        isAvailable: Bool,
        artworkIdentity: String?,
        favoriteAccessibilityLabel: String? = nil,
        actionsAccessibilityLabel: String? = nil
    ) {
        self.id = id
        self.title = title
        self.creator = creator
        self.collection = collection
        self.year = year
        self.duration = duration
        self.isExplicit = isExplicit
        self.isFavorite = isFavorite
        self.isCurrent = isCurrent
        self.isPlaying = isPlaying
        self.isAvailable = isAvailable
        self.artworkIdentity = artworkIdentity
        self.favoriteAccessibilityLabel = favoriteAccessibilityLabel
        self.actionsAccessibilityLabel = actionsAccessibilityLabel
    }
}

public enum NativeMediaTableAction: Hashable, Sendable {
    case select
    case play
    case togglePlayback
    case favorite
    case creator
    case collection
    case actions
    case delete
}

public struct NativeMediaTableActions<ID: Hashable & Sendable> {
    public let select: (@MainActor (ID) -> Void)?
    public let play: (@MainActor (ID) -> Void)?
    public let favorite: (@MainActor (ID) -> Void)?
    public let creator: (@MainActor (ID) -> Void)?
    public let collection: (@MainActor (ID) -> Void)?
    public let actions: (@MainActor (ID) -> Void)?
    public let actionsMenu: (@MainActor (ID, NSButton) -> Void)?
    public let contextMenu: (@MainActor (ID, NSEvent) -> NSMenu?)?

    public init(
        select: (@MainActor (ID) -> Void)? = nil,
        play: (@MainActor (ID) -> Void)? = nil,
        favorite: (@MainActor (ID) -> Void)? = nil,
        creator: (@MainActor (ID) -> Void)? = nil,
        collection: (@MainActor (ID) -> Void)? = nil,
        actions: (@MainActor (ID) -> Void)? = nil,
        actionsMenu: (@MainActor (ID, NSButton) -> Void)? = nil,
        contextMenu: (@MainActor (ID, NSEvent) -> NSMenu?)? = nil
    ) {
        self.select = select
        self.play = play
        self.favorite = favorite
        self.creator = creator
        self.collection = collection
        self.actions = actions
        self.actionsMenu = actionsMenu
        self.contextMenu = contextMenu
    }
}

/// Work performed by one configuration, independent of native layout scheduling.
public struct MediaTableCellUpdate: Equatable, Sendable {
    public let contentApplied: Bool
    public let layoutInvalidated: Bool
}

public struct MediaTableArtworkRequest<ID: Hashable & Sendable>: Equatable, Sendable {
    public let itemID: ID
    public let artworkIdentity: String
    let generation: UInt64

    init(itemID: ID, artworkIdentity: String, generation: UInt64) {
        self.itemID = itemID
        self.artworkIdentity = artworkIdentity
        self.generation = generation
    }
}

public struct MediaTableTypography: Equatable, Sendable {
    public let primaryPointSize: Double
    public let secondaryPointSize: Double
    public let primaryRole: DesignTypographyValue
    public let secondaryRole: DesignTypographyValue
    public let badgeRole: DesignTypographyValue
    public let durationRole: DesignTypographyValue

    public init(
        primaryPointSize: Double,
        secondaryPointSize: Double,
        primaryRole: DesignTypographyValue = DesignTokens.Typography.row,
        secondaryRole: DesignTypographyValue = DesignTokens.Typography.row,
        badgeRole: DesignTypographyValue = DesignTokens.Typography.compactMetadata,
        durationRole: DesignTypographyValue = DesignTokens.Typography.monospacedData
    ) {
        self.primaryPointSize = primaryPointSize
        self.secondaryPointSize = secondaryPointSize
        self.primaryRole = primaryRole
        self.secondaryRole = secondaryRole
        self.badgeRole = badgeRole
        self.durationRole = durationRole
    }

    public static let small = MediaTableTypography(primaryPointSize: 12, secondaryPointSize: 11)
    public static let standard = MediaTableTypography(
        primaryPointSize: DesignTokens.Typography.row.size,
        secondaryPointSize: DesignTokens.Typography.row.size
    )
    public static let large = MediaTableTypography(primaryPointSize: 15, secondaryPointSize: 14)
}

public struct MediaTableCellState: Equatable, Sendable {
    public let isSelected: Bool
    public let isFocused: Bool
    public let isLiveScrolling: Bool
    public let showsArtwork: Bool
    public let density: DesignDensity
    public let typography: MediaTableTypography
    public let environment: DesignNativeEnvironment
    public let favoriteControlWidth: Double
    public let usesPrimaryActionTint: Bool

    public init(
        isSelected: Bool = false,
        isFocused: Bool = false,
        isLiveScrolling: Bool = false,
        showsArtwork: Bool = true,
        density: DesignDensity = .standard,
        typography: MediaTableTypography = .standard,
        environment: DesignNativeEnvironment = MediaTableCellState.defaultEnvironment,
        favoriteControlWidth: Double = DesignTokens.Component.panelMediaTableFavoriteControlWidth.points,
        usesPrimaryActionTint: Bool = false
    ) {
        self.isSelected = isSelected
        self.isFocused = isFocused
        self.isLiveScrolling = isLiveScrolling
        self.showsArtwork = showsArtwork
        self.density = density
        self.typography = typography
        self.environment = environment
        self.favoriteControlWidth = favoriteControlWidth.isFinite && favoriteControlWidth > 0
            ? favoriteControlWidth : DesignTokens.Component.panelMediaTableFavoriteControlWidth.points
        self.usesPrimaryActionTint = usesPrimaryActionTint
    }

    public static let standard = MediaTableCellState()
    public static let compact = MediaTableCellState(density: .compact)

    public static let defaultEnvironment = DesignNativeEnvironment(
        appearance: .light,
        productProfile: .standard,
        density: .standard,
        isIncreasedContrast: false,
        reducesMotion: false,
        reducesTransparency: false
    )
}
#endif
