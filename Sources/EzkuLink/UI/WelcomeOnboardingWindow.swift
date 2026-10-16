import AppKit
import SwiftUI

@MainActor
public final class WelcomeOnboardingWindow: NSObject {
    private static var currentWindow: NSWindow?
    
    public static var isVisible: Bool {
        return currentWindow != nil && currentWindow?.isVisible == true
    }
    
    public static func show() {
        if let existing = currentWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 630),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 480, height: 560)
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        
        let contentView = WelcomeView {
            currentWindow?.close()
            currentWindow = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                MenuBarController.shared?.showPopover()
            }
        }
        
        window.contentView = NSHostingView(rootView: contentView)
        currentWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public static func close() {
        currentWindow?.close()
        currentWindow = nil
    }
}

public struct WelcomeView: View {
    @Environment(\.colorScheme) var colorScheme
    let onGetStarted: () -> Void
    @State private var isHoveringButton = false
    
    public init(onGetStarted: @escaping () -> Void) {
        self.onGetStarted = onGetStarted
    }
    
    public var body: some View {
        ZStack {
            // High-contrast Liquid Glass Background with opaque backing
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .ignoresSafeArea()
            (colorScheme == .dark ? AppColors.brandDark : Color(NSColor.windowBackgroundColor))
                .opacity(colorScheme == .dark ? 0.95 : 0.96)
                .ignoresSafeArea()
            
            // Subtle specular edge highlight
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    colorScheme == .dark
                    ? LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.05), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        colors: [Color.black.opacity(0.15), Color.black.opacity(0.05), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                    lineWidth: 1
                )
                .padding(1)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // App Icon & Header
                    VStack(spacing: 10) {
                        AppLogoView(size: 76, hasShadow: true)
                            .accessibilityHidden(true)
                        
                        VStack(spacing: 4) {
                            Text("Welcome to ezku.link")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(Color(NSColor.labelColor))
                            
                            Text("High-performance Screen Mirroring & 4K Video Streaming")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(NSColor.secondaryLabelColor))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    .accessibilityElement(children: .combine)
                    
                    // How to Use - Step-by-Step Guide
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("HOW TO USE ezku.link")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(NSColor.secondaryLabelColor))
                                .tracking(0.8)
                            
                            Spacer()
                            
                            Text("3 Simple Steps")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(NSColor.tertiaryLabelColor))
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(spacing: 8) {
                            instructionStepRow(
                                stepNumber: "1",
                                icon: MenuBarController.currentToolbarSymbolName(),
                                title: "Find the Icon in Your Top Menu Bar",
                                description: "ezku.link sits in your top macOS menu bar as the standard casting icon. Click it at any time to open casting controls."
                            )
                            
                            instructionStepRow(
                                stepNumber: "2",
                                icon: "square.2.layers.3d",
                                title: "Select Mode: Mirror, Extend to TV, or Video",
                                description: "Mirror your Mac, use your TV as an extended 2nd desktop monitor at 60 FPS, or switch to Video Cast for 4K movies."
                            )
                            
                            instructionStepRow(
                                stepNumber: "3",
                                icon: "tv.badge.wifi",
                                title: "Stream to Smart TV or Web Browser",
                                description: "Click \"Mirror to TV\" for Chromecast, Google TV, or DLNA (Samsung, LG). Or scan the QR code to watch on iPhone, iPad, or PC."
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Menu Bar Visual Spotlight
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(NSColor.labelColor))
                        
                        Text("The menu bar icon is active and ready in your top-right toolbar.")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color(NSColor.secondaryLabelColor))
                        
                        Spacer()
                        
                        HStack(spacing: 5) {
                            Image(systemName: MenuBarController.currentToolbarSymbolName())
                                .font(.system(size: 12, weight: .semibold))
                            Text("ezku.link")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Color(NSColor.labelColor))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : Color.black.opacity(0.06)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                colorScheme == .dark
                                ? Color.white.opacity(0.2)
                                : Color.black.opacity(0.12),
                                lineWidth: 1
                            )
                        )
                    }
                    .padding(10)
                    .background(
                        colorScheme == .dark
                        ? Color.white.opacity(0.04)
                        : Color.black.opacity(0.035)
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                colorScheme == .dark
                                ? Color.white.opacity(0.08)
                                : Color.black.opacity(0.08),
                                lineWidth: 1
                            )
                    )
                    .padding(.horizontal, 20)
                    .accessibilityElement(children: .combine)
                    
                    // Hero Action Button
                    Button(action: onGetStarted) {
                        HStack(spacing: 8) {
                            Text("Open ezku.link")
                                .font(.system(size: 13.5, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            LinearGradient(
                                colors: [Color(white: 0.22), Color.black],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: isHoveringButton ? 10 : 6, y: 3)
                        .scaleEffect(isHoveringButton ? 1.01 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHoveringButton = $0 }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .accessibilityLabel("Open ezku.link menu bar casting controls")
                }
            }
        }
        .frame(minWidth: 500, idealWidth: 540, maxWidth: .infinity, minHeight: 600, idealHeight: 630, maxHeight: .infinity)
    }
    
    private func instructionStepRow(stepNumber: String, icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.25), Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 3, y: 1)
                
                Text(stepNumber)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if icon == "appicon" {
                        AppLogoView(size: 15, cornerRadius: 3.5, hasShadow: false)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(NSColor.labelColor))
                    }
                    
                    Text(title)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(Color(NSColor.labelColor))
                }
                
                Text(description)
                    .font(.system(size: 11.5))
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            colorScheme == .dark
            ? Color.white.opacity(0.04)
            : Color(NSColor.controlBackgroundColor)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : Color(NSColor.separatorColor),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(stepNumber): \(title). \(description)")
    }
}
