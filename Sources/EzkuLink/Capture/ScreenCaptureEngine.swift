import Foundation
@preconcurrency import ScreenCaptureKit
import CoreMedia
import CoreGraphics
import AVFoundation

public enum CaptureTarget: Hashable, Identifiable, @unchecked Sendable {
    case display(SCDisplay)
    case window(SCWindow)
    
    public var id: String {
        switch self {
        case .display(let d): return "display_\(d.displayID)"
        case .window(let w): return "window_\(w.windowID)"
        }
    }
    
    public var title: String {
        switch self {
        case .display(let d):
            return "Display \(d.displayID) (\(d.width)×\(d.height))"
        case .window(let w):
            let appName = w.owningApplication?.applicationName ?? "App"
            let winTitle = w.title ?? "Untitled"
            return "\(appName): \(winTitle)"
        }
    }
}

public protocol ScreenCaptureEngineDelegate: AnyObject, Sendable {
    func screenCaptureEngine(_ engine: ScreenCaptureEngine, didOutputPixelBuffer pixelBuffer: CVPixelBuffer, presentationTime: CMTime)
    func screenCaptureEngine(_ engine: ScreenCaptureEngine, didOutputAudioSampleBuffer sampleBuffer: CMSampleBuffer)
    func screenCaptureEngine(_ engine: ScreenCaptureEngine, didFailWithError error: Error)
}

public final class ScreenCaptureEngine: NSObject, @unchecked Sendable {
    public weak var delegate: ScreenCaptureEngineDelegate?
    
    private var stream: SCStream?
    private let captureQueue = DispatchQueue(label: "com.ezku.capture.video", qos: .userInteractive)
    private let audioQueue = DispatchQueue(label: "com.ezku.capture.audio", qos: .userInteractive)
    
    private(set) public var isRunning = false
    
    public override init() {
        super.init()
    }
    
    /// Fetches all currently shareable displays and non-empty on-screen windows
    public static func fetchShareableContent() async throws -> (displays: [SCDisplay], windows: [SCWindow]) {
        guard CGPreflightScreenCaptureAccess() else {
            return ([], [])
        }
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        let validWindows = content.windows.filter { window in
            guard let title = window.title, !title.isEmpty else { return false }
            guard window.windowLayer == 0 else { return false }
            guard window.isOnScreen else { return false }
            guard window.frame.width > 100 && window.frame.height > 100 else { return false }
            return true
        }
        
        return (content.displays, validWindows)
    }
    
    /// Starts capturing the specified display or window with given fps and resolution scale
    public func startCapture(
        target: CaptureTarget,
        fps: Int = 60,
        scaleFactor: Double = 1.0,
        captureSystemAudio: Bool = true
    ) async throws {
        stopCapture()
        
        let filter: SCContentFilter
        let width: Int
        let height: Int
        
        switch target {
        case .display(let display):
            filter = SCContentFilter(display: display, excludingWindows: [])
            width = max(320, Int(Double(display.width) * scaleFactor))
            height = max(240, Int(Double(display.height) * scaleFactor))
        case .window(let window):
            filter = SCContentFilter(desktopIndependentWindow: window)
            width = max(320, Int(Double(window.frame.width) * scaleFactor))
            height = max(240, Int(Double(window.frame.height) * scaleFactor))
        }
        
        let config = SCStreamConfiguration()
        config.width = width
        config.height = height
        config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(fps))
        // Queue depth of 3 prevents frame backlog for ultra-low latency
        config.queueDepth = 3
        config.showsCursor = true
        config.pixelFormat = kCVPixelFormatType_32BGRA
        
        if captureSystemAudio {
            config.capturesAudio = true
            config.sampleRate = 48000
            config.channelCount = 2
            config.excludesCurrentProcessAudio = true
        }
        
        let newStream = SCStream(filter: filter, configuration: config, delegate: self)
        
        try newStream.addStreamOutput(self, type: .screen, sampleHandlerQueue: captureQueue)
        if captureSystemAudio {
            try newStream.addStreamOutput(self, type: .audio, sampleHandlerQueue: audioQueue)
        }
        
        try await newStream.startCapture()
        self.stream = newStream
        self.isRunning = true
    }
    
    public func stopCapture() {
        guard isRunning, let stream = self.stream else { return }
        self.stream = nil
        self.isRunning = false
        
        Task {
            do {
                try await stream.stopCapture()
            } catch {
                // Ignore stop error
            }
        }
    }
}

extension ScreenCaptureEngine: SCStreamOutput {
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard isRunning else { return }
        
        switch type {
        case .screen:
            guard sampleBuffer.isValid else { return }
            guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
                  let attachments = attachmentsArray.first else {
                return
            }
            
            // Check if frame was dropped or incomplete
            if let statusRaw = attachments[.status] as? Int,
               let status = SCFrameStatus(rawValue: statusRaw),
               status != .complete {
                return
            }
            
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            delegate?.screenCaptureEngine(self, didOutputPixelBuffer: imageBuffer, presentationTime: presentationTime)
            
        case .audio, .microphone:
            guard sampleBuffer.isValid else { return }
            delegate?.screenCaptureEngine(self, didOutputAudioSampleBuffer: sampleBuffer)
            
        @unknown default:
            break
        }
    }
}

extension ScreenCaptureEngine: SCStreamDelegate {
    public func stream(_ stream: SCStream, didStopWithError error: Error) {
        self.isRunning = false
        delegate?.screenCaptureEngine(self, didFailWithError: error)
    }
}
