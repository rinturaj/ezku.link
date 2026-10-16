import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var isInitialLaunch = true
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Set accessory activation policy so no dock icon appears
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Initialize menu bar toolbar item
        menuBarController = MenuBarController()
        
        // Always show the welcome and how-to-use guide window on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            WelcomeOnboardingWindow.show()
        }
        
        // Settle initial launch so reopen events can subsequently trigger popover
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.isInitialLaunch = false
        }
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Do not open popover on initial launch or while welcome/guide window is displayed
        if isInitialLaunch || flag || WelcomeOnboardingWindow.isVisible {
            if WelcomeOnboardingWindow.isVisible {
                WelcomeOnboardingWindow.show()
            }
            return true
        }
        menuBarController?.showPopover()
        return true
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        CastingCoordinator.shared.shutdownServer()
    }
}
