import AppKit
import SwiftUI
import Combine

public enum ToolbarIconStyle: String, CaseIterable, Identifiable, Sendable {
    case airplay = "airplay"
    case screenMirror = "mirror"
    case auto = "auto"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .airplay: return "AirPlay Cast"
        case .screenMirror: return "Screen Mirror"
        case .auto: return "Auto (By Mode)"
        }
    }
    
    public func symbolName(for mode: CastingMode = .screen) -> String {
        switch self {
        case .airplay:
            return "airplayvideo"
        case .screenMirror:
            return "rectangle.on.rectangle"
        case .auto:
            return mode == .screen ? "rectangle.on.rectangle" : "airplayvideo"
        }
    }
}

@MainActor
public final class MenuBarController: NSObject, NSPopoverDelegate {
    public static var shared: MenuBarController?
    
    public static var toolbarIconStyle: ToolbarIconStyle {
        get {
            let raw = UserDefaults.standard.string(forKey: "ezku_toolbar_icon_style") ?? ToolbarIconStyle.airplay.rawValue
            return ToolbarIconStyle(rawValue: raw) ?? .airplay
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "ezku_toolbar_icon_style")
            shared?.updateStatusIcon(isCasting: CastingCoordinator.shared.isCasting)
        }
    }
    
    public static func currentToolbarSymbolName() -> String {
        return toolbarIconStyle.symbolName(for: CastingCoordinator.shared.castingMode)
    }
    
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var anchorWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        super.init()
        MenuBarController.shared = self
        setupStatusItem()
        setupPopover()
        observeCastingState()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            updateStatusIcon(isCasting: false)
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.toolTip = "ezku.link • Screen & 4K Video Cast"
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 600)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: MenuBarPopoverView())
    }
    
    public func popoverDidClose(_ notification: Notification) {
        // Retain anchorWindow safely; do not close during NSPopover cleanup animation
    }
    
    public func hidePopover() {
        popover.close()
    }
    
    public func prepareForModal() {
        hidePopover()
    }
    
    public func finishModal() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.showPopover()
        }
    }
    
    private func observeCastingState() {
        CastingCoordinator.shared.$isCasting
            .receive(on: RunLoop.main)
            .sink { [weak self] isCasting in
                self?.updateStatusIcon(isCasting: isCasting)
            }
            .store(in: &cancellables)
            
        CastingCoordinator.shared.$castingMode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateStatusIcon(isCasting: CastingCoordinator.shared.isCasting)
            }
            .store(in: &cancellables)
    }
    
    public func updateStatusIcon(isCasting: Bool) {
        guard let button = statusItem.button else { return }
        
        if isCasting {
            // Live broadcast icon with red indicator
            let config = NSImage.SymbolConfiguration(paletteColors: [.systemRed, .labelColor])
            if let image = NSImage(systemSymbolName: "record.circle.fill", accessibilityDescription: "Casting Live")?.withSymbolConfiguration(config) {
                image.isTemplate = false
                button.image = image
            }
        } else {
            // Apple standard casting or mirroring icon
            let symbolName = Self.currentToolbarSymbolName()
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
            if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "ezku.link")?.withSymbolConfiguration(config) {
                image.isTemplate = true
                button.image = image
            }
        }
    }
    
    @objc public func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        }
    }
    
    public func showPopover() {
        guard let button = statusItem.button, let window = button.window else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.showPopover()
            }
            return
        }
        
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen = screen else { return }
        
        // Wait if macOS has not laid out the status item horizontally yet (initial startup 0.0)
        if window.frame.origin.x <= 0 || window.frame.size.width <= 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.showPopover()
            }
            return
        }
        
        NSApp.activate(ignoringOtherApps: true)
        
        if !popover.isShown {
            let isOffscreen = window.frame.origin.y >= (screen.frame.maxY - 5)
            
            if isOffscreen {
                // Menu bar is auto-hidden and currently slid above the screen edge.
                // Use a retained invisible anchor window at the top of screen aligned with status item X.
                let anchorRect = NSRect(
                    x: window.frame.origin.x,
                    y: screen.frame.maxY - 1,
                    width: window.frame.size.width,
                    height: 1
                )
                
                if let existing = anchorWindow {
                    existing.setFrame(anchorRect, display: false)
                    existing.orderFront(nil)
                } else {
                    let anchor = NSWindow(
                        contentRect: anchorRect,
                        styleMask: [.borderless],
                        backing: .buffered,
                        defer: false
                    )
                    anchor.isOpaque = false
                    anchor.backgroundColor = .clear
                    anchor.ignoresMouseEvents = true
                    anchor.isReleasedWhenClosed = false
                    anchor.orderFront(nil)
                    self.anchorWindow = anchor
                }
                
                if let anchorView = anchorWindow?.contentView {
                    popover.show(relativeTo: anchorView.bounds, of: anchorView, preferredEdge: .minY)
                }
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
        
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
    }
}
