import SwiftUI
import AppKit

public enum AppColors {
    // Anthropic Brand Palette
    public static let brandDark = Color(red: 0x14 / 255.0, green: 0x14 / 255.0, blue: 0x13 / 255.0)       // #141413 Dark
    public static let brandLight = Color(red: 0xFA / 255.0, green: 0xF9 / 255.0, blue: 0xF5 / 255.0)      // #faf9f5 Light
    public static let brandMidGray = Color(red: 0xB0 / 255.0, green: 0xAE / 255.0, blue: 0xA5 / 255.0)    // #b0aea5 Mid Gray
    public static let brandLightGray = Color(red: 0xE8 / 255.0, green: 0xE6 / 255.0, blue: 0xDC / 255.0)  // #e8e6dc Light Gray
    public static let brandOrange = Color(red: 0xD9 / 255.0, green: 0x77 / 255.0, blue: 0x57 / 255.0)     // #d97757 Primary Warm Accent
    public static let brandBlue = Color(red: 0x6A / 255.0, green: 0x9B / 255.0, blue: 0xCC / 255.0)       // #6a9bcc Slate Blue
    public static let brandGreen = Color(red: 0x78 / 255.0, green: 0x8C / 255.0, blue: 0x5D / 255.0)      // #788c5d Sage Green

    // MARK: - Semantic Dynamic Hierarchy Tokens (HIG compliant)
    public static var primaryText: Color {
        Color(NSColor.labelColor)
    }
    
    public static var secondaryText: Color {
        Color(NSColor.secondaryLabelColor)
    }
    
    public static var tertiaryText: Color {
        Color(NSColor.tertiaryLabelColor)
    }
    
    public static var quaternaryText: Color {
        Color(NSColor.quaternaryLabelColor)
    }
    
    public static var separator: Color {
        Color(NSColor.separatorColor)
    }
    
    public static var controlBackground: Color {
        Color(NSColor.controlBackgroundColor)
    }
    
    public static var windowBackground: Color {
        Color(NSColor.windowBackgroundColor)
    }

    // Primary Button Gradient: Sleek dark onyx gradient with subtle depth
    public static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(white: 0.22), Color(red: 0.08, green: 0.08, blue: 0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Brand Accent Gradient (Warm terracotta to amber)
    public static var brandAccentGradient: LinearGradient {
        LinearGradient(
            colors: [brandOrange, Color(red: 0xBF / 255.0, green: 0x62 / 255.0, blue: 0x43 / 255.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Tab Selected Pill Gradient: Sleek dark gradient
    public static var tabSelectedGradient: LinearGradient {
        LinearGradient(
            colors: [Color(white: 0.24), Color(red: 0.07, green: 0.07, blue: 0.07)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Active / Stop Gradient: Vibrant Apple Red / Terracotta blend
    public static var activeCastingGradient: LinearGradient {
        LinearGradient(
            colors: [Color.red, Color(red: 0.85, green: 0.15, blue: 0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Subtle Button Shadow
    public static var buttonShadow: Color {
        Color.black.opacity(0.35)
    }
}

public struct AppLogoView: View {
    public var size: CGFloat = 32
    public var cornerRadius: CGFloat? = nil
    public var hasShadow: Bool = true
    
    public init(size: CGFloat = 32, cornerRadius: CGFloat? = nil, hasShadow: Bool = true) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.hasShadow = hasShadow
    }
    
    public var body: some View {
        let fallbackRadius = cornerRadius ?? (size * 0.223)
        if let nsImage = AppLogoView.loadIcon() {
            let imgView = Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
            
            if let cr = cornerRadius {
                imgView
                    .clipShape(RoundedRectangle(cornerRadius: cr, style: .continuous))
                    .shadow(color: hasShadow ? Color.black.opacity(0.35) : Color.clear, radius: size * 0.1, y: size * 0.05)
            } else {
                imgView
                    .shadow(color: hasShadow ? Color.black.opacity(0.35) : Color.clear, radius: size * 0.1, y: size * 0.05)
            }
        } else {
            // Fallback if asset is missing
            ZStack {
                RoundedRectangle(cornerRadius: fallbackRadius, style: .continuous)
                    .fill(AppColors.primaryGradient)
                    .frame(width: size, height: size)
                Image(systemName: "airplayvideo")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    public static func loadIcon() -> NSImage? {
        // 1. App Bundle Icon Name (set via CFBundleIconFile in Info.plist)
        if let appIcon = NSImage(named: NSImage.applicationIconName), appIcon.isValid {
            return appIcon
        }
        // 2. Direct bundle resources (PNG or ICNS)
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        if let icnsUrl = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let img = NSImage(contentsOf: icnsUrl) {
            return img
        }
        if let resourcePath = Bundle.main.resourcePath {
            let pngPath = (resourcePath as NSString).appendingPathComponent("AppIcon.png")
            if FileManager.default.fileExists(atPath: pngPath), let img = NSImage(contentsOfFile: pngPath) {
                return img
            }
            let icnsPath = (resourcePath as NSString).appendingPathComponent("AppIcon.icns")
            if FileManager.default.fileExists(atPath: icnsPath), let img = NSImage(contentsOfFile: icnsPath) {
                return img
            }
        }
        // 3. Fallback direct paths for development
        let paths = [
            "/Users/rinturajc/FrontEnd/ezkuCasting/Resources/AppIcon.png",
            "/Users/rinturajc/FrontEnd/ezkuCasting/Resources/AppIcon.icns",
            "/Users/rinturajc/FrontEnd/ezkuCasting/icons/appicon_tight.png",
            "/Users/rinturajc/FrontEnd/ezkuCasting/icons/appicon_transparent.png"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path),
               let img = NSImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }
}
