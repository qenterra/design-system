#if canImport(SwiftUI)
import SwiftUI

public extension Image {
    init(designIcon icon: DesignIcon) {
        self.init(systemName: icon.systemName)
    }
}

public extension Color {
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

private struct DesignColorComponents {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init?(_ source: String) {
        let value = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            let hex = String(value.dropFirst())
            guard hex.count == 6, let number = UInt64(hex, radix: 16) else { return nil }
            red = Double((number >> 16) & 0xFF) / 255
            green = Double((number >> 8) & 0xFF) / 255
            blue = Double(number & 0xFF) / 255
            alpha = 1
            return
        }

        guard value.lowercased().hasPrefix("rgba("), value.hasSuffix(")") else { return nil }
        let arguments = value.dropFirst(5).dropLast().split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard
            arguments.count == 4,
            let redChannel = Double(arguments[0]),
            let greenChannel = Double(arguments[1]),
            let blueChannel = Double(arguments[2]),
            let opacity = Double(arguments[3]),
            (0 ... 255).contains(redChannel),
            (0 ... 255).contains(greenChannel),
            (0 ... 255).contains(blueChannel),
            (0 ... 1).contains(opacity)
        else { return nil }

        red = redChannel / 255
        green = greenChannel / 255
        blue = blueChannel / 255
        alpha = opacity
    }
}
#endif
