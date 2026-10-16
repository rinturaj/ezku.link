import Foundation
import CoreMedia
import CoreVideo
import CoreImage
import Metal

public protocol HardwareVideoEncoderDelegate: AnyObject, Sendable {
    func hardwareVideoEncoder(_ encoder: HardwareVideoEncoder, didEncodeVideoData data: Data, presentationTimeMs: UInt64)
}

public final class HardwareVideoEncoder: @unchecked Sendable {
    public weak var delegate: HardwareVideoEncoderDelegate?
    
    private let ciContext: CIContext
    private let encodeQueue = DispatchQueue(label: "com.ezku.encoder.video", qos: .userInteractive)
    
    // Concurrency control: drop frame if previous frame is still encoding
    private var isEncoding = false
    private let encodingLock = NSLock()
    
    // Quality setting: 0.1 ... 1.0 (default 0.8)
    public var compressionQuality: Float = 0.78
    
    // Telemetry
    private(set) public var currentFPS: Double = 0.0
    private(set) public var currentBitrateMbps: Double = 0.0
    private(set) public var lastEncodeDurationMs: Double = 0.0
    
    private var frameCount: Int = 0
    private var bytesCount: Int = 0
    private var lastTelemetryUpdate: TimeInterval = ProcessInfo.processInfo.systemUptime
    
    public init() {
        // Initialize Metal-backed CIContext for zero-copy GPU hardware encoding
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: metalDevice, options: [
                .useSoftwareRenderer: false,
                .cacheIntermediates: false
            ])
        } else {
            self.ciContext = CIContext(options: [.useSoftwareRenderer: false])
        }
    }
    
    /// Encodes a CVPixelBuffer into an ultra-low latency compressed JPEG frame
    public func encode(pixelBuffer: CVPixelBuffer, presentationTime: CMTime) {
        // Drop frame if encoder is currently busy to maintain ultra-low latency
        encodingLock.lock()
        if isEncoding {
            encodingLock.unlock()
            return
        }
        isEncoding = true
        encodingLock.unlock()
        
        let targetQuality = self.compressionQuality
        let ptsMs = UInt64(presentationTime.seconds * 1000.0)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        encodeQueue.async { [weak self] in
            guard let self = self else { return }
            let startTime = CFAbsoluteTimeGetCurrent()
            
            defer {
                self.encodingLock.lock()
                self.isEncoding = false
                self.encodingLock.unlock()
            }
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            let options: [CIImageRepresentationOption: Any] = [
                kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: targetQuality
            ]
            
            guard let jpegData = self.ciContext.jpegRepresentation(of: ciImage, colorSpace: colorSpace, options: options) else {
                return
            }
            
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            self.updateTelemetry(bytes: jpegData.count, durationMs: duration)
            
            self.delegate?.hardwareVideoEncoder(self, didEncodeVideoData: jpegData, presentationTimeMs: ptsMs)
        }
    }
    
    private func updateTelemetry(bytes: Int, durationMs: Double) {
        self.frameCount += 1
        self.bytesCount += bytes
        self.lastEncodeDurationMs = durationMs
        
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = now - self.lastTelemetryUpdate
        if elapsed >= 1.0 {
            self.currentFPS = Double(self.frameCount) / elapsed
            self.currentBitrateMbps = (Double(self.bytesCount * 8) / elapsed) / 1_000_000.0
            
            self.frameCount = 0
            self.bytesCount = 0
            self.lastTelemetryUpdate = now
        }
    }
    
    public func resetTelemetry() {
        self.frameCount = 0
        self.bytesCount = 0
        self.currentFPS = 0.0
        self.currentBitrateMbps = 0.0
        self.lastEncodeDurationMs = 0.0
        self.lastTelemetryUpdate = ProcessInfo.processInfo.systemUptime
    }
}
