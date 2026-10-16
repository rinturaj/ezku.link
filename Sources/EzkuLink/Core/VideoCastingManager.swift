import Foundation
import AVFoundation
import AppKit

public struct VideoMetadata: Sendable, Identifiable {
    public var id: String { url.absoluteString }
    public let url: URL
    public let title: String
    public let duration: Double
    public let durationFormatted: String
    public let resolution: String
    public let fileSizeBytes: UInt64
    public let fileSizeFormatted: String
    public let thumbnail: NSImage?
    
    public init(
        url: URL,
        title: String,
        duration: Double,
        durationFormatted: String,
        resolution: String,
        fileSizeBytes: UInt64,
        fileSizeFormatted: String,
        thumbnail: NSImage?
    ) {
        self.url = url
        self.title = title
        self.duration = duration
        self.durationFormatted = durationFormatted
        self.resolution = resolution
        self.fileSizeBytes = fileSizeBytes
        self.fileSizeFormatted = fileSizeFormatted
        self.thumbnail = thumbnail
    }
}

public enum VideoMetadataLoader {
    public static func load(from url: URL) async -> VideoMetadata {
        let title = url.deletingPathExtension().lastPathComponent
        let asset = AVURLAsset(url: url)
        
        var durationSec: Double = 0
        var resolutionStr = "HD"
        
        if let duration = try? await asset.load(.duration) {
            let sec = duration.seconds
            if !sec.isNaN && sec > 0 {
                durationSec = sec
            }
        }
        
        if let tracks = try? await asset.loadTracks(withMediaType: .video), let firstTrack = tracks.first {
            if let size = try? await firstTrack.load(.naturalSize) {
                let w = Int(abs(size.width))
                let h = Int(abs(size.height))
                if w > 0 && h > 0 {
                    if w >= 3840 || h >= 2160 {
                        resolutionStr = "4K UHD (\(w)×\(h))"
                    } else if w >= 1920 || h >= 1080 {
                        resolutionStr = "1080p Full HD"
                    } else if w >= 1280 || h >= 720 {
                        resolutionStr = "720p HD"
                    } else {
                        resolutionStr = "\(w)×\(h)"
                    }
                }
            }
        }
        
        // Format file size
        var sizeBytes: UInt64 = 0
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let sz = attrs[.size] as? UInt64 {
            sizeBytes = sz
        }
        let formattedSize = ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
        
        // Format duration
        let formattedDuration = formatTime(durationSec)
        
        // Generate thumbnail
        var thumbnailImage: NSImage? = nil
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 270)
        
        let thumbTime = CMTime(seconds: min(2.0, durationSec * 0.1), preferredTimescale: 600)
        if let (cgImage, _) = try? await generator.image(at: thumbTime) {
            thumbnailImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }
        
        return VideoMetadata(
            url: url,
            title: title,
            duration: durationSec,
            durationFormatted: formattedDuration,
            resolution: resolutionStr,
            fileSizeBytes: sizeBytes,
            fileSizeFormatted: formattedSize,
            thumbnail: thumbnailImage
        )
    }
    
    public static func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds > 0 else { return "00:00" }
        let total = Int(seconds)
        let s = total % 60
        let m = (total / 60) % 60
        let h = total / 3600
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}
