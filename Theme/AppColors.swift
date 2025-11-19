import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AppColors {
    // Color Palette
    static let inkBlack = Color(hex: "0d1b2a")
    static let prussianBlue = Color(hex: "1b263b")
    static let duskBlue = Color(hex: "415a77")
    static let dustyDenim = Color(hex: "778da9")
    static let alabasterGrey = Color(hex: "e0e1dd")
    
    // Semantic Colors - Now with dark mode support
    static let background = Color(light: alabasterGrey, dark: inkBlack)
    static let foreground = Color(light: inkBlack, dark: Color(hex: "e8eaed"))
    static let card = Color(light: .white, dark: prussianBlue)
    static let primary = prussianBlue
    static let secondary = Color(light: Color(hex: "f5f5f5"), dark: Color(hex: "1e2936"))
    static let muted = Color(light: Color(hex: "f0f0f0"), dark: Color(hex: "2a3847"))
    static let mutedForeground = Color(light: dustyDenim, dark: Color(hex: "a8b8cc"))
    static let border = Color(light: dustyDenim, dark: duskBlue)
    static let input = Color(light: Color(hex: "f5f5f5"), dark: Color(hex: "1e2936"))
    static let accent = duskBlue
    static let accentForeground = Color(light: alabasterGrey, dark: Color(hex: "f0f2f5"))
    static let destructive = Color(hex: "dc2626")
    static let success = duskBlue
    static let warning = Color(hex: "d97706")
    
    // Design system aliases for DashboardView compatibility
    static let textPrimary = foreground
    static let textSecondary = mutedForeground
    
    // Adaptive gradient colors for headers
    static let primaryGradientStart = Color(light: prussianBlue, dark: dustyDenim)
    static let primaryGradientEnd = Color(light: duskBlue, dark: Color(hex: "9fb5d1"))
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    init(light: Color, dark: Color) {
        #if os(iOS)
        self.init(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
        #else
        self = light
        #endif
    }
}

extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return dark
            default:
                return light
            }
        }
    }
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.duskBlue, AppColors.dustyDenim],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.secondary, AppColors.card],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

