import SwiftUI
import AppKit

// MARK: - Liquid Glass View Modifier (High Contrast Light & Dark)
public struct LiquidGlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    public var cornerRadius: CGFloat
    
    public init(cornerRadius: CGFloat = 14) {
        self.cornerRadius = cornerRadius
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : Color(NSColor.controlBackgroundColor)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        colorScheme == .dark
                        ? LinearGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.06),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [
                                Color.black.opacity(0.12),
                                Color.black.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: colorScheme == .dark
                ? Color.black.opacity(0.25)
                : Color.black.opacity(0.05),
                radius: 6, y: 2
            )
    }
}

extension View {
    public func liquidGlassCard(cornerRadius: CGFloat = 14) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Visual Effect View Helper for macOS Vibrancy
public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode
    
    public init(material: NSVisualEffectView.Material, blendingMode: NSVisualEffectView.BlendingMode) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Apple Fluid Motion Device Row Button Style
public struct AppleDeviceRowButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    public var isSelected: Bool = false
    
    public init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                        ? AppColors.brandBlue.opacity(colorScheme == .dark ? 0.22 : 0.12)
                        : (configuration.isPressed
                            ? Color.white.opacity(colorScheme == .dark ? 0.12 : 0.08)
                            : Color.white.opacity(colorScheme == .dark ? 0.045 : 0.035))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected
                        ? AppColors.brandBlue.opacity(0.4)
                        : (configuration.isPressed
                            ? Color.white.opacity(0.18)
                            : Color.white.opacity(colorScheme == .dark ? 0.08 : 0.05)),
                        lineWidth: 0.8
                    )
            )
            .scaleEffect((configuration.isPressed && !reduceMotion) ? 0.985 : 1.0)
            .animation(reduceMotion ? .none : .spring(response: 0.25, dampingFraction: 0.88), value: configuration.isPressed)
    }
}

// MARK: - Footer Subtle Hover Button Style (Native macOS Feedback)
public struct FooterHoverButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        isHovered
                        ? (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        : Color.clear
                    )
            )
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
    }
}
