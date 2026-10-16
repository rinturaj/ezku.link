import Foundation
import AppKit
import AVFoundation
import CoreGraphics
import Combine

@MainActor
public final class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()
    
    @Published public private(set) var hasScreenRecordingPermission: Bool = false
    @Published public private(set) var hasMicrophonePermission: Bool = false
    
    private init() {
        checkPermissions()
    }
    
    public func checkPermissions() {
        hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
        
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        hasMicrophonePermission = (micStatus == .authorized)
    }
    
    @discardableResult
    public func requestScreenRecordingPermission() -> Bool {
        let granted = CGRequestScreenCaptureAccess()
        hasScreenRecordingPermission = granted
        return granted
    }
    
    public func requestMicrophonePermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
            self.hasMicrophonePermission = granted
        }
        return granted
    }
    
    public func openScreenRecordingSettings() {
        // macOS 13+ Ventura / Sonoma / Sequoia Settings URL
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
