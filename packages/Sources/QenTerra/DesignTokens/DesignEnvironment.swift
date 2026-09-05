import Foundation

public enum DesignAppearancePreference: String, CaseIterable, Sendable {
    case system
    case light
    case dark
}

public enum DesignProductProfile: String, Sendable {
    case standard
    case cadence
}

public enum DesignDensity: String, Sendable {
    case compact
    case standard
    case comfortable
}

public struct DesignSystemConfiguration: Equatable, Sendable {
    public var appearance: DesignAppearancePreference
    public var productProfile: DesignProductProfile
    public var density: DesignDensity

    public init(
        appearance: DesignAppearancePreference = .system,
        productProfile: DesignProductProfile = .standard,
        density: DesignDensity = .standard
    ) {
        self.appearance = appearance
        self.productProfile = productProfile
        self.density = density
    }
}

public struct DesignNativeEnvironment: Equatable, Sendable {
    public let appearance: DesignAppearance
    public let productProfile: DesignProductProfile
    public let density: DesignDensity
    public let isIncreasedContrast: Bool
    public let reducesMotion: Bool
    public let reducesTransparency: Bool

    public init(
        appearance: DesignAppearance,
        productProfile: DesignProductProfile,
        density: DesignDensity,
        isIncreasedContrast: Bool,
        reducesMotion: Bool,
        reducesTransparency: Bool
    ) {
        self.appearance = appearance
        self.productProfile = productProfile
        self.density = density
        self.isIncreasedContrast = isIncreasedContrast
        self.reducesMotion = reducesMotion
        self.reducesTransparency = reducesTransparency
    }
}

#if canImport(SwiftUI)
import SwiftUI

private struct DesignSystemConfigurationKey: EnvironmentKey {
    static let defaultValue = DesignSystemConfiguration()
}

private struct DesignProductProfileKey: EnvironmentKey {
    static let defaultValue: DesignProductProfile? = nil
}

private struct DesignDensityKey: EnvironmentKey {
    static let defaultValue: DesignDensity? = nil
}

private struct DesignNativeEnvironmentKey: EnvironmentKey {
    static let defaultValue: DesignNativeEnvironment? = nil
}

public extension EnvironmentValues {
    var designSystemConfiguration: DesignSystemConfiguration {
        get { self[DesignSystemConfigurationKey.self] }
        set { self[DesignSystemConfigurationKey.self] = newValue }
    }

    var designProductProfile: DesignProductProfile {
        get { self[DesignProductProfileKey.self] ?? designSystemConfiguration.productProfile }
        set { self[DesignProductProfileKey.self] = newValue }
    }

    var designDensity: DesignDensity {
        get { self[DesignDensityKey.self] ?? designSystemConfiguration.density }
        set { self[DesignDensityKey.self] = newValue }
    }

    /// An explicit value takes precedence; otherwise resolves the current native and design inputs.
    var designNativeEnvironment: DesignNativeEnvironment {
        get {
            resolvedDesignNativeEnvironment(
                colorScheme: colorScheme,
                colorSchemeContrast: colorSchemeContrast,
                reducesMotion: accessibilityReduceMotion,
                reducesTransparency: accessibilityReduceTransparency
            )
        }
        set { self[DesignNativeEnvironmentKey.self] = newValue }
    }
}

extension EnvironmentValues {
    func resolvedDesignNativeEnvironment(
        colorScheme: ColorScheme,
        colorSchemeContrast: ColorSchemeContrast,
        reducesMotion: Bool,
        reducesTransparency: Bool
    ) -> DesignNativeEnvironment {
        if let explicit = self[DesignNativeEnvironmentKey.self] { return explicit }
        var configuration = designSystemConfiguration
        configuration.productProfile = designProductProfile
        configuration.density = designDensity
        return configuration.resolvedNativeEnvironment(
            colorScheme: colorScheme,
            colorSchemeContrast: colorSchemeContrast,
            reducesMotion: reducesMotion,
            reducesTransparency: reducesTransparency
        )
    }
}

public extension View {
    func designSystem(_ configuration: DesignSystemConfiguration) -> some View {
        modifier(DesignSystemEnvironmentModifier(configuration: configuration))
    }
}

private struct DesignSystemEnvironmentModifier: ViewModifier {
    let configuration: DesignSystemConfiguration

    func body(content: Content) -> some View {
        content
            .environment(\.designSystemConfiguration, configuration)
            .environment(\.designProductProfile, configuration.productProfile)
            .environment(\.designDensity, configuration.density)
            .preferredColorScheme(configuration.appearance.colorScheme)
    }
}

extension DesignSystemConfiguration {
    func resolvedNativeEnvironment(
        colorScheme: ColorScheme,
        colorSchemeContrast: ColorSchemeContrast,
        reducesMotion: Bool,
        reducesTransparency: Bool
    ) -> DesignNativeEnvironment {
        DesignNativeEnvironment(
            appearance: appearance.resolvedAppearance(colorScheme: colorScheme),
            productProfile: productProfile,
            density: density,
            isIncreasedContrast: colorSchemeContrast == .increased,
            reducesMotion: reducesMotion,
            reducesTransparency: reducesTransparency
        )
    }
}

private extension DesignAppearancePreference {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    func resolvedAppearance(colorScheme: ColorScheme) -> DesignAppearance {
        switch self {
        case .system:
            colorScheme == .dark ? .dark : .light
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
#endif
