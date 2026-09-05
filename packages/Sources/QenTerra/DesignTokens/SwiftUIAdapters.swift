#if canImport(SwiftUI)
import SwiftUI

public extension Image {
    init(designIcon icon: DesignIcon) {
        self.init(systemName: icon.systemName)
    }
}

public extension Color {
    init(designToken value: DesignColorValue) {
        #if canImport(AppKit)
        self.init(nsColor: NSColor.designToken(value))
        #else
        self.init(designToken: value, appearance: .light)
        #endif
    }

    init(designToken value: DesignColorValue, appearance: DesignAppearance) {
        let source = value.value(for: appearance)
        guard let components = DesignColorComponents(source) else {
            self = .clear
            return
        }
        self.init(
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: components.alpha
        )
    }
}

public extension DesignAppearancePreference {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

public extension DesignTypographyValue {
    var swiftUIWeight: Font.Weight {
        switch weight {
        case 650...: .bold
        case 575...: .semibold
        case 450...: .medium
        default: .regular
        }
    }
}

#endif
