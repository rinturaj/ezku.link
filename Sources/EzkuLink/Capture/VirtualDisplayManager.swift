import Foundation
import CoreGraphics
import AppKit

public enum ExtendedDisplayResolution: String, CaseIterable, Identifiable, Sendable {
    case fhd1080p = "1080p FHD (1920×1080)"
    case qhd1440p = "1440p QHD (2560×1440)"
    case uhd4K = "4K UHD (3840×2160)"
    
    public var id: String { rawValue }
    
    public var shortTitle: String {
        switch self {
        case .fhd1080p: return "1080p"
        case .qhd1440p: return "1440p"
        case .uhd4K: return "4K"
        }
    }
    
    public var width: UInt {
        switch self {
        case .fhd1080p: return 1920
        case .qhd1440p: return 2560
        case .uhd4K: return 3840
        }
    }
    
    public var height: UInt {
        switch self {
        case .fhd1080p: return 1080
        case .qhd1440p: return 1440
        case .uhd4K: return 2160
        }
    }
}

/// Manages native macOS virtual displays using CoreGraphics runtime APIs.
/// Creates a virtual extended monitor that macOS treats as a physical second display,
/// allowing users to drag windows onto their Smart TV and use it as an extended desktop.
@MainActor
public final class VirtualDisplayManager: ObservableObject {
    public static let shared = VirtualDisplayManager()
    
    @Published public private(set) var isExtendedDisplayActive: Bool = false
    @Published public private(set) var activeDisplayID: CGDirectDisplayID?
    @Published public var selectedResolution: ExtendedDisplayResolution = .fhd1080p
    
    private var virtualDisplayInstance: AnyObject?
    
    public var isSupported: Bool {
        return NSClassFromString("CGVirtualDisplay") != nil &&
               NSClassFromString("CGVirtualDisplayDescriptor") != nil
    }
    
    public init() {}
    
    /// Creates and activates a virtual extended screen with the requested resolution.
    /// Returns the newly allocated `CGDirectDisplayID`.
    @discardableResult
    public func createExtendedDisplay(resolution: ExtendedDisplayResolution? = nil) -> CGDirectDisplayID? {
        let res = resolution ?? selectedResolution
        
        // If already active with the same resolution, return the current display ID
        if isExtendedDisplayActive, let id = activeDisplayID, res == selectedResolution {
            return id
        }
        
        // If active with a different resolution, destroy first
        if isExtendedDisplayActive {
            destroyExtendedDisplay()
        }
        
        guard let descClass = NSClassFromString("CGVirtualDisplayDescriptor") as? NSObject.Type,
              let dispClass = NSClassFromString("CGVirtualDisplay") as? NSObject.Type,
              let settingsClass = NSClassFromString("CGVirtualDisplaySettings") as? NSObject.Type,
              let modeClass = NSClassFromString("CGVirtualDisplayMode") as? NSObject.Type else {
            print("[VirtualDisplayManager] CGVirtualDisplay APIs not available on this macOS version.")
            return nil
        }
        
        let desc = descClass.init()
        let setQueueSel = NSSelectorFromString("setDispatchQueue:")
        if desc.responds(to: setQueueSel) {
            _ = desc.perform(setQueueSel, with: DispatchQueue.main)
        }
        
        desc.setValue("EzkuLink TV Extended", forKey: "name")
        desc.setValue(UInt32(8192), forKey: "maxPixelsWide")
        desc.setValue(UInt32(8192), forKey: "maxPixelsHigh")
        desc.setValue(CGSize(width: 527, height: 296), forKey: "sizeInMillimeters")
        desc.setValue(UInt32(0x5678), forKey: "productID")
        desc.setValue(UInt32(0x1234), forKey: "vendorID")
        desc.setValue(UInt32(1), forKey: "serialNum")
        
        let allocSel = NSSelectorFromString("alloc")
        let initSel = NSSelectorFromString("initWithDescriptor:")
        guard let allocated = dispClass.perform(allocSel)?.takeUnretainedValue() else {
            print("[VirtualDisplayManager] Failed to allocate CGVirtualDisplay.")
            return nil
        }
        
        guard let display = allocated.perform(initSel, with: desc)?.takeUnretainedValue() as AnyObject? else {
            print("[VirtualDisplayManager] Failed to initialize CGVirtualDisplay.")
            return nil
        }
        
        guard let displayIDVal = (display as AnyObject).value(forKey: "displayID") as? CGDirectDisplayID,
              displayIDVal != 0 else {
            print("[VirtualDisplayManager] Invalid displayID returned from CGVirtualDisplay.")
            return nil
        }
        
        let settings = settingsClass.init()
        settings.setValue(UInt32(0), forKey: "hiDPI")
        
        guard let modeAlloc = modeClass.perform(allocSel)?.takeUnretainedValue() else {
            return nil
        }
        
        let modeInitSel = NSSelectorFromString("initWithWidth:height:refreshRate:")
        typealias ModeInitFunc = @convention(c) (AnyObject, Selector, UInt, UInt, Double) -> AnyObject
        let modeInitMethod = unsafeBitCast(modeAlloc.method(for: modeInitSel), to: ModeInitFunc.self)
        let mode = modeInitMethod(modeAlloc, modeInitSel, res.width, res.height, 60.0)
        
        settings.setValue([mode], forKey: "modes")
        
        let applySel = NSSelectorFromString("applySettings:")
        typealias ApplyFunc = @convention(c) (AnyObject, Selector, AnyObject) -> Bool
        let applyMethod = unsafeBitCast(display.method(for: applySel), to: ApplyFunc.self)
        let success = applyMethod(display, applySel, settings)
        
        guard success else {
            print("[VirtualDisplayManager] Failed to apply virtual display settings.")
            return nil
        }
        
        self.virtualDisplayInstance = display
        self.activeDisplayID = displayIDVal
        self.isExtendedDisplayActive = true
        self.selectedResolution = res
        
        print("[VirtualDisplayManager] Extended virtual display created successfully (ID: \(displayIDVal), \(res.rawValue)).")
        return displayIDVal
    }
    
    /// Tears down the virtual display, automatically restoring all moved windows to the primary screen.
    public func destroyExtendedDisplay() {
        guard isExtendedDisplayActive || virtualDisplayInstance != nil else { return }
        
        print("[VirtualDisplayManager] Tearing down virtual display ID: \(activeDisplayID ?? 0)...")
        if let disp = virtualDisplayInstance {
            let invalidateSel = NSSelectorFromString("invalidate")
            if disp.responds(to: invalidateSel) {
                _ = disp.perform(invalidateSel)
            }
        }
        self.virtualDisplayInstance = nil
        self.activeDisplayID = nil
        self.isExtendedDisplayActive = false
    }
    
    /// Opens macOS System Settings -> Displays so the user can re-arrange display positions (left/right/top).
    public func openDisplayPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
