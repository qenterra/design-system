#if os(macOS)
import CoreGraphics
import QenTerraDesignTokens

public enum MediaTableColumn: String, CaseIterable, Identifiable, Codable, Sendable {
    case collection
    case year
    case duration

    public var id: Self {
        self
    }
}

public struct MediaTableResolvedWidths: Equatable, Sendable {
    public let title: Double
    public let collection: Double
    public let year: Double
    public let duration: Double

    public init(title: Double, collection: Double, year: Double, duration: Double) {
        self.title = title
        self.collection = collection
        self.year = year
        self.duration = duration
    }

    public subscript(column: MediaTableColumn) -> Double {
        switch column {
        case .collection: collection
        case .year: year
        case .duration: duration
        }
    }
}

public struct MediaTableGeometry: Equatable, Sendable {
    public let density: DesignDensity
    private let favoriteWidth: Double

    public init(
        density: DesignDensity,
        favoriteControlWidth: Double = DesignTokens.Component.panelMediaTableFavoriteControlWidth.points
    ) {
        self.density = density
        favoriteWidth = favoriteControlWidth.isFinite && favoriteControlWidth > 0
            ? favoriteControlWidth : DesignTokens.Component.panelMediaTableFavoriteControlWidth.points
    }

    public var rowHeight: CGFloat {
        switch density {
        case .compact: metric(DesignTokens.Component.panelMediaTableCompactRowHeight)
        case .standard: metric(DesignTokens.Component.panelMediaTableStandardRowHeight)
        case .comfortable: metric(DesignTokens.Component.panelMediaTableComfortableRowHeight)
        }
    }

    public var headerHeight: CGFloat {
        switch density {
        case .compact: metric(DesignTokens.Component.panelMediaTableCompactHeaderHeight)
        case .standard: metric(DesignTokens.Component.panelMediaTableStandardHeaderHeight)
        case .comfortable: metric(DesignTokens.Component.panelMediaTableComfortableHeaderHeight)
        }
    }

    public var artworkSize: CGFloat {
        switch density {
        case .compact: metric(DesignTokens.Component.panelMediaTableCompactArtworkSize)
        case .standard: metric(DesignTokens.Component.panelMediaTableStandardArtworkSize)
        case .comfortable: metric(DesignTokens.Component.panelMediaTableComfortableArtworkSize)
        }
    }

    public var horizontalInset: CGFloat {
        metric(DesignTokens.Component.panelMediaTableHorizontalInset)
    }

    public var selectionHorizontalInset: CGFloat {
        metric(DesignTokens.Component.panelMediaTableSelectionHorizontalInset)
    }

    public var selectionVerticalInset: CGFloat {
        metric(DesignTokens.Component.panelMediaTableSelectionVerticalInset)
    }

    public var columnSpacing: CGFloat {
        metric(DesignTokens.Component.panelMediaTableColumnSpacing)
    }

    public var actionWidth: CGFloat {
        metric(DesignTokens.Component.panelMediaTableActionWidth)
    }

    public var favoriteControlWidth: CGFloat {
        CGFloat(favoriteWidth)
    }

    public var songContentSpacing: CGFloat {
        metric(DesignTokens.Component.panelMediaTableSongContentSpacing)
    }

    public var minimumSongWidth: Double {
        DesignTokens.Component.panelMediaTableMinimumSongWidth.points
    }

    public var lineHeight: CGFloat {
        metric(DesignTokens.Component.panelMediaTableLineHeight)
    }

    public var lineGap: CGFloat {
        metric(DesignTokens.Component.panelMediaTableLineGap)
    }

    public var explicitBadgeGap: CGFloat {
        metric(DesignTokens.Component.panelMediaTableExplicitBadgeGap)
    }

    public var explicitBadgeWidth: CGFloat {
        metric(DesignTokens.Component.panelMediaTableExplicitBadgeWidth)
    }

    public var explicitBadgeHeight: CGFloat {
        metric(DesignTokens.Component.panelMediaTableExplicitBadgeHeight)
    }

    public func fixedWidth(for column: MediaTableColumn) -> Double {
        switch column {
        case .collection: DesignTokens.Component.panelMediaTableCollectionWidth.points
        case .year: DesignTokens.Component.panelMediaTableYearWidth.points
        case .duration: DesignTokens.Component.panelMediaTableDurationWidth.points
        }
    }

    public func resolvedWidths(
        availableWidth: Double,
        columns: [MediaTableColumn]
    ) -> MediaTableResolvedWidths {
        let available = availableWidth.isFinite && availableWidth > 0 ? availableWidth : 1
        let chrome = Double(horizontalInset * 2 + actionWidth)
            + Double(max(columns.count, 0) + 2) * Double(columnSpacing)
        let content = available > chrome ? available - chrome : 1
        let collection = columns.contains(.collection) ? fixedWidth(for: .collection) : 0
        let year = columns.contains(.year) ? fixedWidth(for: .year) : 0
        let duration = columns.contains(.duration) ? fixedWidth(for: .duration) : 0
        let fixed = collection + year + duration
        let title = content > fixed ? content - fixed : 1
        return MediaTableResolvedWidths(
            title: title.isFinite ? title : Double.greatestFiniteMagnitude,
            collection: collection,
            year: year,
            duration: duration
        )
    }

    private func metric(_ value: DesignComponentMetric) -> CGFloat {
        CGFloat(value.points)
    }
}
#endif
