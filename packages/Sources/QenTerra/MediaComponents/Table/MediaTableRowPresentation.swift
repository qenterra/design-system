#if os(macOS)
import Foundation
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
        artworkIdentity: String?
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
    }
}

public enum NativeMediaTableAction: Equatable, Sendable {
    case select
    case play
    case togglePlayback
    case favorite
    case creator
    case collection
    case actions
    case delete
}

public struct MediaTableCellState: Equatable, Sendable {
    public let isSelected: Bool
    public let isFocused: Bool
    public let isLiveScrolling: Bool
    public let showsArtwork: Bool
    public let density: DesignDensity
    public let environment: DesignNativeEnvironment

    public init(
        isSelected: Bool = false,
        isFocused: Bool = false,
        isLiveScrolling: Bool = false,
        showsArtwork: Bool = true,
        density: DesignDensity = .standard,
        environment: DesignNativeEnvironment = MediaTableCellState.defaultEnvironment
    ) {
        self.isSelected = isSelected
        self.isFocused = isFocused
        self.isLiveScrolling = isLiveScrolling
        self.showsArtwork = showsArtwork
        self.density = density
        self.environment = environment
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
