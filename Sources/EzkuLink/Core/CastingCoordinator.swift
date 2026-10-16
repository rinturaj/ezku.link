import Foundation
import SwiftUI
import Combine
import ScreenCaptureKit
import CoreMedia
import AVFoundation

public enum CastingMode: String, CaseIterable, Identifiable {
    case screen = "Screen Mirror"
    case videoFile = "Cast Video"
    
    public var id: String { rawValue }
}

public enum ScreenCastType: String, CaseIterable, Identifiable {
    case mirror = "Mirror Screen"
    case extended = "Extended Screen (TV)"
    
    public var id: String { rawValue }
}

public enum PerformanceMode: String, CaseIterable, Identifiable {
    case ultra60 = "Ultra Low Latency (60 FPS)"
    case retina = "Retina Native (60 FPS)"
    case eco = "Battery Saver (30 FPS)"
    
    public var id: String { rawValue }
    
    public var fps: Int {
        switch self {
        case .ultra60, .retina: return 60
        case .eco: return 30
        }
    }
    
    public var scaleFactor: Double {
        switch self {
        case .ultra60: return 0.85
        case .retina: return 1.0
        case .eco: return 0.65
        }
    }
    
    public var compressionQuality: Float {
        switch self {
        case .ultra60: return 0.75
        case .retina: return 0.85
        case .eco: return 0.60
        }
    }
}

@MainActor
public final class CastingCoordinator: ObservableObject {
    public static let shared = CastingCoordinator()
    
    // Core Engines
    private let captureEngine = ScreenCaptureEngine()
    private let videoEncoder = HardwareVideoEncoder()
    private let streamingServer = StreamingServer(port: 8765)
    private let tvDiscovery = SmartTVDiscovery()
    private let dlnaController = DLNAController.shared
    private let googleCastController = GoogleCastController.shared
    
    // Mode
    @Published public var castingMode: CastingMode = .screen
    
    // UI State
    @Published public private(set) var isCasting: Bool = false
    @Published public private(set) var activeViewers: Int = 0
    @Published public private(set) var fps: Double = 0.0
    @Published public private(set) var bitrateMbps: Double = 0.0
    @Published public private(set) var latencyMs: Double = 0.0
    @Published public private(set) var statusMessage: String = "Ready to cast"
    
    // Dedicated Video File Casting State
    @Published public private(set) var selectedVideoURL: URL?
    @Published public private(set) var videoMetadata: VideoMetadata?
    @Published public private(set) var isVideoPlaying: Bool = false
    @Published public private(set) var videoCurrentTime: Double = 0.0
    @Published public private(set) var videoDuration: Double = 0.0
    @Published public private(set) var videoWebURL: String = ""
    @Published public private(set) var videoStreamURL: String = ""
    
    // Fullscreen Video Detection
    @Published public private(set) var detectedFullscreenWindow: SCWindow?
    @Published public var autoSwitchFullscreenVideo: Bool = true
    
    // Smart TV State
    @Published public private(set) var discoveredTVs: [DiscoveredTV] = []
    @Published public private(set) var activeTV: DiscoveredTV?
    @Published public private(set) var isScanningTVs: Bool = false
    @Published public private(set) var tvStreamingURL: String = ""
    @Published public private(set) var tvWebURL: String = ""
    
    // Target Selection
    @Published public var availableDisplays: [SCDisplay] = []
    @Published public var availableWindows: [SCWindow] = []
    @Published public var selectedTarget: CaptureTarget?
    
    // Extended Screen Support
    public let virtualDisplayManager = VirtualDisplayManager.shared
    @Published public var screenCastType: ScreenCastType = .mirror
    
    // Settings
    @Published public var performanceMode: PerformanceMode = .ultra60 {
        didSet {
            videoEncoder.compressionQuality = performanceMode.compressionQuality
        }
    }
    @Published public var includeSystemAudio: Bool = true
    
    // Network Info
    @Published public private(set) var localURL: String = ""
    @Published public private(set) var qrCodeImage: NSImage?
    
    private var telemetryTimer: Timer?
    
    private init() {
        captureEngine.delegate = self
        videoEncoder.delegate = self
        streamingServer.delegate = self
        tvDiscovery.delegate = self
        googleCastController.delegate = self
        
        updateNetworkInfo()
        startTVScan()
        
        do {
            try streamingServer.start()
        } catch {
            print("[CastingCoordinator] Server startup note: \(error.localizedDescription)")
        }
    }
    
    public func updateNetworkInfo() {
        let ip = NetworkUtils.getLocalIPAddress()
        let url = "http://\(ip):\(streamingServer.port)"
        self.localURL = url
        self.tvStreamingURL = "\(url)/stream.mjpg"
        self.tvWebURL = "\(url)/tv"
        self.videoWebURL = "\(url)/video"
        self.videoStreamURL = "\(url)/media/video"
        self.qrCodeImage = NetworkUtils.generateQRCode(from: url, size: 220)
    }

    public func startTVScan() {
        isScanningTVs = true
        tvDiscovery.startDiscovery()
        // Reset scan indicator after 6 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            self?.isScanningTVs = false
        }
    }
    
    public func castToSmartTV(_ tv: DiscoveredTV) async {
        // Ensure local casting is running
        if !isCasting {
            await startCasting()
        }
        
        guard isCasting else { return }
        
        do {
            self.statusMessage = "Connecting to \(tv.name)..."
            
            if tv.type == .googlecast {
                try await googleCastController.cast(to: tv, tvWebURL: tvWebURL)
                self.activeTV = tv
                self.statusMessage = "Casting to \(tv.name)"
            } else if tv.controlURL != nil {
                try await dlnaController.castStream(to: tv, streamURL: tvStreamingURL)
                self.activeTV = tv
                self.statusMessage = "Casting to \(tv.name)"
            } else {
                self.activeTV = tv
                self.statusMessage = "TV: Open \(tvWebURL)"
            }
        } catch {
            self.statusMessage = "TV Cast Error: \(error.localizedDescription)"
        }
    }
    
    public func disconnectSmartTV() async {
        guard let tv = activeTV else { return }
        if tv.type == .googlecast {
            googleCastController.disconnect()
        } else {
            _ = try? await dlnaController.stopStream(on: tv)
        }
        self.activeTV = nil
        self.statusMessage = "Disconnected from TV"
    }
    
    public func refreshTargets() async {
        guard CGPreflightScreenCaptureAccess() else {
            return
        }
        do {
            let (displays, windows) = try await ScreenCaptureEngine.fetchShareableContent()
            self.availableDisplays = displays
            self.availableWindows = windows
            
            // Default to first display if nothing selected
            if selectedTarget == nil, let firstDisplay = displays.first {
                self.selectedTarget = .display(firstDisplay)
            }
            
            checkForFullscreenVideo()
        } catch {
            self.statusMessage = "Could not fetch screens: \(error.localizedDescription)"
        }
    }
    
    public func startCasting() async {
        guard !isCasting else { return }
        
        do {
            updateNetworkInfo()
            if !streamingServer.isListening {
                try streamingServer.start()
            }
            
            videoEncoder.resetTelemetry()
            videoEncoder.compressionQuality = performanceMode.compressionQuality
            
            let targetToCapture: CaptureTarget
            
            if screenCastType == .extended {
                self.statusMessage = "Starting extended display..."
                if !virtualDisplayManager.isExtendedDisplayActive {
                    guard let newDisplayID = virtualDisplayManager.createExtendedDisplay() else {
                        self.statusMessage = "Extended display creation failed"
                        return
                    }
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    await refreshTargets()
                    
                    if let virtualSCDisplay = availableDisplays.first(where: { $0.displayID == newDisplayID }) {
                        targetToCapture = .display(virtualSCDisplay)
                        self.selectedTarget = targetToCapture
                    } else if let firstDisplay = availableDisplays.first {
                        targetToCapture = .display(firstDisplay)
                    } else {
                        self.statusMessage = "Could not attach to extended display"
                        return
                    }
                } else if let activeID = virtualDisplayManager.activeDisplayID,
                          let virtualSCDisplay = availableDisplays.first(where: { $0.displayID == activeID }) {
                    targetToCapture = .display(virtualSCDisplay)
                    self.selectedTarget = targetToCapture
                } else if let firstDisplay = availableDisplays.first {
                    targetToCapture = .display(firstDisplay)
                } else {
                    self.statusMessage = "Could not attach to extended display"
                    return
                }
            } else {
                // Mirror Mode: strictly mirror selected display or window. NEVER create virtual display!
                if selectedTarget == nil {
                    await refreshTargets()
                }
                guard let target = selectedTarget else {
                    self.statusMessage = "No screen or window selected"
                    return
                }
                targetToCapture = target
            }
            
            try await captureEngine.startCapture(
                target: targetToCapture,
                fps: performanceMode.fps,
                scaleFactor: performanceMode.scaleFactor,
                captureSystemAudio: includeSystemAudio
            )
            
            self.isCasting = true
            self.statusMessage = screenCastType == .extended ? "Extended Desktop Live" : "Broadcasting live"
            startTelemetryLoop()
        } catch {
            self.isCasting = false
            self.statusMessage = "Cast error: \(error.localizedDescription)"
        }
    }
    
    public func stopCasting() {
        guard isCasting else { return }
        
        if activeTV != nil {
            Task {
                await disconnectSmartTV()
            }
        }
        
        captureEngine.stopCapture()
        stopTelemetryLoop()
        
        self.isCasting = false
        self.fps = 0.0
        self.bitrateMbps = 0.0
        self.latencyMs = 0.0
        self.statusMessage = "Casting paused"
    }

    /// Explicitly creates the extended virtual monitor in macOS
    @discardableResult
    public func createExtendedScreen(resolution: ExtendedDisplayResolution? = nil) async -> Bool {
        let res = resolution ?? virtualDisplayManager.selectedResolution
        self.statusMessage = "Creating extended display (\(res.shortTitle))..."
        guard let newDisplayID = virtualDisplayManager.createExtendedDisplay(resolution: res) else {
            self.statusMessage = "Failed to create extended display"
            return false
        }
        self.screenCastType = .extended
        try? await Task.sleep(nanoseconds: 600_000_000)
        await refreshTargets()
        
        if let virtualSCDisplay = availableDisplays.first(where: { $0.displayID == newDisplayID }) {
            self.selectedTarget = .display(virtualSCDisplay)
            if isCasting {
                captureEngine.stopCapture()
                try? await captureEngine.startCapture(
                    target: .display(virtualSCDisplay),
                    fps: performanceMode.fps,
                    scaleFactor: performanceMode.scaleFactor,
                    captureSystemAudio: includeSystemAudio
                )
                self.statusMessage = "Extended Desktop Live"
            } else {
                self.statusMessage = "Extended display active"
            }
        }
        return true
    }
    
    /// Explicitly deletes and tears down the extended virtual monitor from macOS
    public func removeExtendedScreen() async {
        self.statusMessage = "Removing extended display..."
        virtualDisplayManager.destroyExtendedDisplay()
        self.screenCastType = .mirror
        try? await Task.sleep(nanoseconds: 300_000_000)
        await refreshTargets()
        
        if let firstDisplay = availableDisplays.first {
            self.selectedTarget = .display(firstDisplay)
            if isCasting {
                captureEngine.stopCapture()
                try? await captureEngine.startCapture(
                    target: .display(firstDisplay),
                    fps: performanceMode.fps,
                    scaleFactor: performanceMode.scaleFactor,
                    captureSystemAudio: includeSystemAudio
                )
                self.statusMessage = "Broadcasting primary screen"
            } else {
                self.statusMessage = "Ready to cast"
            }
        }
    }

    /// Dynamically switches between Mirror Screen and Extended Screen
    public func switchScreenCastType(to newType: ScreenCastType) async {
        guard self.screenCastType != newType else { return }
        self.screenCastType = newType
        
        if newType == .mirror {
            // When switching to mirror mode, remove any lingering extended display
            if virtualDisplayManager.isExtendedDisplayActive {
                virtualDisplayManager.destroyExtendedDisplay()
                try? await Task.sleep(nanoseconds: 300_000_000)
                await refreshTargets()
            }
            if isCasting {
                self.statusMessage = "Switching to Mirror Screen..."
                captureEngine.stopCapture()
                if let firstDisplay = availableDisplays.first {
                    let target: CaptureTarget = .display(firstDisplay)
                    self.selectedTarget = target
                    try? await captureEngine.startCapture(
                        target: target,
                        fps: performanceMode.fps,
                        scaleFactor: performanceMode.scaleFactor,
                        captureSystemAudio: includeSystemAudio
                    )
                    self.statusMessage = "Broadcasting live"
                }
            }
        } else if newType == .extended {
            // When switching to extended, only create if casting or explicitly active
            if isCasting {
                self.statusMessage = "Switching to Extended Screen..."
                captureEngine.stopCapture()
                guard let newDisplayID = virtualDisplayManager.createExtendedDisplay() else {
                    self.statusMessage = "Failed to create extended screen"
                    return
                }
                try? await Task.sleep(nanoseconds: 600_000_000)
                await refreshTargets()
                if let virtualSCDisplay = availableDisplays.first(where: { $0.displayID == newDisplayID }) {
                    let target: CaptureTarget = .display(virtualSCDisplay)
                    self.selectedTarget = target
                    try? await captureEngine.startCapture(
                        target: target,
                        fps: performanceMode.fps,
                        scaleFactor: performanceMode.scaleFactor,
                        captureSystemAudio: includeSystemAudio
                    )
                    self.statusMessage = "Extended Desktop Live"
                }
            }
        }
    }
    
    /// Updates the resolution of the extended display
    public func updateExtendedResolution(_ resolution: ExtendedDisplayResolution) async {
        virtualDisplayManager.selectedResolution = resolution
        if virtualDisplayManager.isExtendedDisplayActive {
            if isCasting && screenCastType == .extended {
                captureEngine.stopCapture()
            }
            guard let newDisplayID = virtualDisplayManager.createExtendedDisplay(resolution: resolution) else {
                return
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
            await refreshTargets()
            if isCasting && screenCastType == .extended,
               let virtualSCDisplay = availableDisplays.first(where: { $0.displayID == newDisplayID }) {
                let target: CaptureTarget = .display(virtualSCDisplay)
                self.selectedTarget = target
                try? await captureEngine.startCapture(
                    target: target,
                    fps: performanceMode.fps,
                    scaleFactor: performanceMode.scaleFactor,
                    captureSystemAudio: includeSystemAudio
                )
            }
        }
    }

    public func shutdownServer() {
        stopCasting()
        streamingServer.stop()
    }
    
    private func startTelemetryLoop() {
        telemetryTimer?.invalidate()
        telemetryTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.fps = self.videoEncoder.currentFPS
                self.bitrateMbps = self.videoEncoder.currentBitrateMbps
                self.latencyMs = self.videoEncoder.lastEncodeDurationMs
            }
        }
    }
    
    private func stopTelemetryLoop() {
        telemetryTimer?.invalidate()
        telemetryTimer = nil
    }
    
    // MARK: - Video File Management
    public func selectVideoFile(url: URL) {
        self.selectedVideoURL = url
        self.streamingServer.setActiveVideoFile(url)
        self.videoCurrentTime = 0.0
        updateNetworkInfo()
        if !streamingServer.isListening {
            try? streamingServer.start()
        }
        self.videoWebURL = "\(localURL)/video"
        self.videoStreamURL = "\(localURL)/media/video"
        self.statusMessage = "Loading video..."
        
        Task {
            let meta = await VideoMetadataLoader.load(from: url)
            self.videoMetadata = meta
            self.videoDuration = meta.duration
            self.statusMessage = "Video loaded: \(meta.title)"
        }
    }
    
    public func clearVideoFile() {
        if isVideoPlaying {
            stopVideoCast()
        }
        self.selectedVideoURL = nil
        self.videoMetadata = nil
        self.videoDuration = 0.0
        self.videoCurrentTime = 0.0
        self.streamingServer.setActiveVideoFile(nil)
        self.statusMessage = "Video cleared"
    }
    
    public func castVideoToSmartTV(_ tv: DiscoveredTV) async {
        guard let url = selectedVideoURL else {
            self.statusMessage = "Please select a video file first"
            return
        }
        
        updateNetworkInfo()
        if !streamingServer.isListening {
            try? streamingServer.start()
        }
        
        do {
            self.statusMessage = "Streaming video to \(tv.name)..."
            let videoTitle = videoMetadata?.title ?? url.deletingPathExtension().lastPathComponent
            let videoEndpoint = "\(localURL)/media/video"
            
            if tv.type == .googlecast {
                try await googleCastController.castVideo(to: tv, videoURL: videoEndpoint, title: videoTitle)
            } else if tv.controlURL != nil {
                try await dlnaController.castVideo(to: tv, videoURL: videoEndpoint, title: videoTitle)
            }
            
            self.activeTV = tv
            self.isVideoPlaying = true
            self.statusMessage = "Streaming video on \(tv.name)"
        } catch {
            self.statusMessage = "Video Cast Error: \(error.localizedDescription)"
        }
    }
    
    public func playVideo() {
        guard let tv = activeTV else { return }
        Task {
            if tv.type == .googlecast {
                try? await googleCastController.playMedia()
            } else {
                try? await dlnaController.playVideo(on: tv)
            }
            self.isVideoPlaying = true
        }
    }
    
    public func pauseVideo() {
        guard let tv = activeTV else { return }
        Task {
            if tv.type == .googlecast {
                try? await googleCastController.pauseMedia()
            } else {
                try? await dlnaController.pauseVideo(on: tv)
            }
            self.isVideoPlaying = false
        }
    }
    
    public func seekVideo(to seconds: Double) {
        self.videoCurrentTime = seconds
        guard let tv = activeTV else { return }
        Task {
            if tv.type == .googlecast {
                try? await googleCastController.seekMedia(to: seconds)
            } else if tv.controlURL != nil {
                try? await dlnaController.seekVideo(on: tv, to: seconds)
            }
        }
    }
    
    public func stopVideoCast() {
        Task {
            await disconnectSmartTV()
            self.isVideoPlaying = false
            self.statusMessage = "Video stopped"
        }
    }
    
    // MARK: - Fullscreen Video Detection
    public func checkForFullscreenVideo() {
        guard let display = availableDisplays.first else { return }
        let mediaApps = ["QuickTime", "VLC", "IINA", "Safari", "Chrome", "TV", "Infuse", "mpv"]
        
        let candidate = availableWindows.first { win in
            let app = win.owningApplication?.applicationName ?? ""
            let isMediaApp = mediaApps.contains(where: { app.localizedCaseInsensitiveContains($0) })
            let coversDisplay = abs(win.frame.width - CGFloat(display.width)) < 15 && abs(win.frame.height - CGFloat(display.height)) < 15
            let title = win.title ?? ""
            let isVideoTitle = title.localizedCaseInsensitiveContains("mp4")
                || title.localizedCaseInsensitiveContains("mov")
                || title.localizedCaseInsensitiveContains("mkv")
                || title.localizedCaseInsensitiveContains("youtube")
                || title.localizedCaseInsensitiveContains("netflix")
            return coversDisplay && (isMediaApp || isVideoTitle)
        }
        
        self.detectedFullscreenWindow = candidate
        
        // Auto-switch if enabled and screen casting is active
        if autoSwitchFullscreenVideo, let win = candidate, isCasting, castingMode == .screen {
            if case .window(let currentWin) = selectedTarget, currentWin.windowID == win.windowID {
                // already focused
            } else {
                self.selectedTarget = .window(win)
                self.performanceMode = .retina
                self.statusMessage = "Auto-focused on fullscreen video: \(win.owningApplication?.applicationName ?? "Video")"
            }
        }
    }
}

// MARK: - ScreenCaptureEngineDelegate
extension CastingCoordinator: ScreenCaptureEngineDelegate {
    public nonisolated func screenCaptureEngine(_ engine: ScreenCaptureEngine, didOutputPixelBuffer pixelBuffer: CVPixelBuffer, presentationTime: CMTime) {
        videoEncoder.encode(pixelBuffer: pixelBuffer, presentationTime: presentationTime)
    }
    
    public nonisolated func screenCaptureEngine(_ engine: ScreenCaptureEngine, didOutputAudioSampleBuffer sampleBuffer: CMSampleBuffer) {
        // Extract audio PCM buffer
        var blockBufferOut: CMBlockBuffer?
        var audioBufferList = AudioBufferList()
        
        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBufferOut
        )
        
        guard status == noErr, let buffer = audioBufferList.mBuffers.mData else { return }
        let length = Int(audioBufferList.mBuffers.mDataByteSize)
        guard length > 0 else { return }
        
        let pcmData = Data(bytes: buffer, count: length)
        let ptsMs = UInt64(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds * 1000.0)
        
        streamingServer.broadcastAudioData(pcmData: pcmData, presentationTimeMs: ptsMs)
    }
    
    public nonisolated func screenCaptureEngine(_ engine: ScreenCaptureEngine, didFailWithError error: Error) {
        Task { @MainActor in
            self.stopCasting()
            self.statusMessage = "Capture failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - HardwareVideoEncoderDelegate
extension CastingCoordinator: HardwareVideoEncoderDelegate {
    public nonisolated func hardwareVideoEncoder(_ encoder: HardwareVideoEncoder, didEncodeVideoData data: Data, presentationTimeMs: UInt64) {
        streamingServer.broadcastVideoFrame(jpegData: data, presentationTimeMs: presentationTimeMs)
    }
}

// MARK: - StreamingServerDelegate
extension CastingCoordinator: StreamingServerDelegate {
    public nonisolated func streamingServer(_ server: StreamingServer, didUpdateClientCount count: Int) {
        Task { @MainActor in
            self.activeViewers = count
        }
    }
}

// MARK: - SmartTVDiscoveryDelegate
extension CastingCoordinator: SmartTVDiscoveryDelegate {
    public nonisolated func smartTVDiscovery(_ discovery: SmartTVDiscovery, didUpdateTVs tvs: [DiscoveredTV]) {
        Task { @MainActor in
            self.discoveredTVs = tvs
        }
    }
}

// MARK: - GoogleCastControllerDelegate
extension CastingCoordinator: GoogleCastControllerDelegate {
    public nonisolated func googleCastController(_ controller: GoogleCastController, didUpdateMediaStatus isPlaying: Bool, currentTime: Double, duration: Double) {
        Task { @MainActor in
            self.isVideoPlaying = isPlaying
            if currentTime > 0 { self.videoCurrentTime = currentTime }
            if duration > 0 { self.videoDuration = duration }
        }
    }
}


