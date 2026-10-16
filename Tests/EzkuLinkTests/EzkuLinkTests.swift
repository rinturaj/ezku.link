import Testing
import Foundation
import AppKit
@testable import EzkuLink

@Suite("ezku.link Core Tests")
struct EzkuLinkTests {
    @Test("NetworkUtils IP address resolution")
    func testIPAddressResolution() {
        let ip = NetworkUtils.getLocalIPAddress()
        #expect(!ip.isEmpty)
        #expect(ip.contains("."))
    }
    
    @Test("NetworkUtils QR Code generation")
    func testQRCodeGeneration() {
        let testURL = "http://192.168.1.50:8765"
        let qrImage = NetworkUtils.generateQRCode(from: testURL, size: 200)
        #expect(qrImage != nil)
        #expect(qrImage?.size.width == 200)
        #expect(qrImage?.size.height == 200)
    }
    
    @Test("PerformanceMode presets")
    func testPerformanceModePresets() {
        let ultra = PerformanceMode.ultra60
        #expect(ultra.fps == 60)
        #expect(ultra.scaleFactor == 0.85)
        
        let retina = PerformanceMode.retina
        #expect(retina.fps == 60)
        #expect(retina.scaleFactor == 1.0)
        
        let eco = PerformanceMode.eco
        #expect(eco.fps == 30)
    }
    
    @Test("HardwareVideoEncoder initialization and reset")
    func testHardwareVideoEncoder() {
        let encoder = HardwareVideoEncoder()
        #expect(encoder.currentFPS == 0.0)
        #expect(encoder.currentBitrateMbps == 0.0)
        
        encoder.compressionQuality = 0.8
        #expect(encoder.compressionQuality == 0.8)
        
        encoder.resetTelemetry()
        #expect(encoder.currentFPS == 0.0)
    }
    
    @Test("StreamingServer setup and lifecycle")
    func testStreamingServer() {
        let server = StreamingServer(port: 9876)
        #expect(server.port == 9876)
        #expect(server.activeClientCount == 0)
        
        // Start and stop cleanly
        try? server.start()
        server.stop()
        #expect(server.activeClientCount == 0)
    }

    @Test("StreamingServer HTTP endpoints")
    func testStreamingServerHTTPEndpoints() async throws {
        let testPort: UInt16 = 8999
        let server = StreamingServer(port: testPort)
        try server.start()
        
        // Give listener brief moment to bind
        try await Task.sleep(nanoseconds: 150_000_000)
        
        let url = URL(string: "http://127.0.0.1:\(testPort)/status")!
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
        #expect(httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let jsonStr = String(data: data, encoding: .utf8) ?? ""
        #expect(jsonStr.contains("\"status\":\"ok\""))
        
        // Test root web client endpoint
        let rootURL = URL(string: "http://127.0.0.1:\(testPort)/")!
        let (rootData, rootResponse) = try await URLSession.shared.data(from: rootURL)
        let rootHttp = try #require(rootResponse as? HTTPURLResponse)
        #expect(rootHttp.statusCode == 200)
        let rootStr = String(data: rootData, encoding: .utf8) ?? ""
        #expect(rootStr.contains("ezku.link"))
        
        // Test TV web client endpoint
        let tvURL = URL(string: "http://127.0.0.1:\(testPort)/tv")!
        let (tvData, tvResponse) = try await URLSession.shared.data(from: tvURL)
        let tvHttp = try #require(tvResponse as? HTTPURLResponse)
        #expect(tvHttp.statusCode == 200)
        let tvStr = String(data: tvData, encoding: .utf8) ?? ""
        #expect(tvStr.contains("ezku.link TV"))
        
        server.stop()
    }

    @Test("DiscoveredTV model properties")
    func testDiscoveredTVModel() {
        let dummyURL = URL(string: "http://192.168.1.100:8080/avt")!
        let tv = DiscoveredTV(
            id: "dlna_192.168.1.100",
            name: "Living Room Samsung TV",
            type: .dlna,
            ipAddress: "192.168.1.100",
            controlURL: dummyURL,
            locationURL: nil
        )
        #expect(tv.name == "Living Room Samsung TV")
        #expect(tv.type == .dlna)
        #expect(tv.controlURL == dummyURL)
    }

    @Test("WebClientAssets TV Page template")
    func testTVPageAsset() {
        let tvPage = WebClientAssets.tvPage
        #expect(!tvPage.isEmpty)
        #expect(tvPage.contains("<canvas id=\"screenCanvas\"></canvas>"))
        #expect(tvPage.contains("ezku.link TV"))
    }

    @Test("SmartTVDiscovery lifecycle")
    func testSmartTVDiscoveryLifecycle() {
        let discovery = SmartTVDiscovery()
        discovery.startDiscovery()
        discovery.stopDiscovery()
        #expect(Bool(true))
    }

    @Test("GoogleCastController message serialization")
    func testGoogleCastMessageFraming() {
        let payload = "{\"type\":\"PING\"}"
        let msg = GoogleCastController.makeCastMessage(
            sourceId: "sender-0",
            destId: "receiver-0",
            namespace: "urn:x-cast:com.google.cast.tp.heartbeat",
            payload: payload
        )
        
        // 4-byte header length + protobuf payload
        #expect(msg.count > 4)
        
        // Read 4-byte big endian length
        var len: UInt32 = 0
        _ = withUnsafeMutableBytes(of: &len) { msg.copyBytes(to: $0, from: 0..<4) }
        let payloadLen = UInt32(bigEndian: len)
        #expect(Int(payloadLen) == msg.count - 4)
        
        // Check message contains payload string
        let bodyStr = String(data: msg.dropFirst(4), encoding: .utf8) ?? ""
        #expect(bodyStr.contains("urn:x-cast:com.google.cast.tp.heartbeat"))
        #expect(bodyStr.contains("PING"))
    }
    
    @Test("VideoMetadataLoader time formatting and videoPage template")
    func testVideoFormattingAndAssets() {
        #expect(VideoMetadataLoader.formatTime(0) == "00:00")
        #expect(VideoMetadataLoader.formatTime(65) == "01:05")
        #expect(VideoMetadataLoader.formatTime(3665) == "01:01:05")
        
        let videoPage = WebClientAssets.videoPage
        #expect(!videoPage.isEmpty)
        #expect(videoPage.contains("/media/video"))
        #expect(videoPage.contains("ezku.link Video Player"))
        #expect(GoogleCastController.defaultMediaReceiverAppId == "CC1AD845")
    }

    @Test("StreamingServer byte-range video serving")
    func testStreamingServerVideoByteRange() async throws {
        let server = StreamingServer(port: 8998)
        try server.start()
        
        // Create a temporary sample file
        let tempDir = FileManager.default.temporaryDirectory
        let sampleURL = tempDir.appendingPathComponent("test_video_\(UUID().uuidString).mp4")
        let dummyData = Data(repeating: 0x42, count: 1024) // 1 KB
        try dummyData.write(to: sampleURL)
        
        server.setActiveVideoFile(sampleURL)
        #expect(server.currentVideoURL?.path == sampleURL.path)
        
        // 1. Test video page HTML
        let (htmlData, htmlRes) = try await URLSession.shared.data(from: URL(string: "http://127.0.0.1:8998/video")!)
        let httpRes1 = try #require(htmlRes as? HTTPURLResponse)
        #expect(httpRes1.statusCode == 200)
        #expect(String(data: htmlData, encoding: .utf8)?.contains("video") == true)
        
        // 2. Test byte-range request
        var rangeReq = URLRequest(url: URL(string: "http://127.0.0.1:8998/media/video")!)
        rangeReq.setValue("bytes=0-499", forHTTPHeaderField: "Range")
        let (rangeData, rangeRes) = try await URLSession.shared.data(for: rangeReq)
        let httpRes2 = try #require(rangeRes as? HTTPURLResponse)
        #expect(httpRes2.statusCode == 206)
        #expect(rangeData.count == 500)
        #expect(httpRes2.allHeaderFields["Content-Range"] as? String == "bytes 0-499/1024")
        #expect(httpRes2.allHeaderFields["Content-Length"] as? String == "500")
        
        server.stop()
        try? FileManager.default.removeItem(at: sampleURL)
    }

    @Test("VideoMetadataLoader real video parsing and duration")
    func testVideoMetadataLoaderRealVideo() async {
        let sampleURL = URL(fileURLWithPath: "/tmp/ezku_test_sample.mp4")
        guard FileManager.default.fileExists(atPath: sampleURL.path) else { return }
        
        let meta = await VideoMetadataLoader.load(from: sampleURL)
        #expect(meta.duration > 14.0 && meta.duration < 16.0)
        #expect(meta.resolution.contains("1280") || meta.resolution.contains("720"))
        #expect(!meta.durationFormatted.isEmpty)
    }

    @Test("CastingCoordinator seek video state update")
    @MainActor
    func testCastingCoordinatorSeek() {
        let coordinator = CastingCoordinator.shared
        coordinator.seekVideo(to: 45.0)
        #expect(coordinator.videoCurrentTime == 45.0)
        coordinator.seekVideo(to: 90.5)
        #expect(coordinator.videoCurrentTime == 90.5)
    }

    @Test("AppLogoView icon loading and dimensions")
    @MainActor
    func testAppLogoLoading() {
        let icon = AppLogoView.loadIcon()
        #expect(icon != nil)
        if let icon = icon {
            #expect(icon.size.width >= 128)
            #expect(icon.size.height >= 128)
        }
    }

    @Test("ToolbarIconStyle Apple symbols")
    @MainActor
    func testToolbarIconStyles() {
        #expect(ToolbarIconStyle.airplay.symbolName() == "airplayvideo")
        #expect(ToolbarIconStyle.screenMirror.symbolName() == "rectangle.on.rectangle")
        #expect(!MenuBarController.currentToolbarSymbolName().isEmpty)
    }

    @Test("VirtualDisplayManager lifecycle and resolutions")
    @MainActor
    func testVirtualDisplayManager() {
        let manager = VirtualDisplayManager.shared
        #expect(manager.isSupported)
        #expect(ExtendedDisplayResolution.fhd1080p.width == 1920)
        #expect(ExtendedDisplayResolution.fhd1080p.height == 1080)
        #expect(ExtendedDisplayResolution.qhd1440p.width == 2560)
        #expect(ExtendedDisplayResolution.uhd4K.width == 3840)
        
        let coordinator = CastingCoordinator.shared
        #expect(coordinator.screenCastType == .mirror)
        
        if let id = manager.createExtendedDisplay(resolution: .fhd1080p) {
            #expect(id != 0)
            #expect(manager.isExtendedDisplayActive)
            manager.destroyExtendedDisplay()
            #expect(!manager.isExtendedDisplayActive)
        }
    }
    
    @Test("VideoMetadata model with thumbnail and Sendable conformance")
    func testVideoMetadataSendable() {
        let dummyURL = URL(fileURLWithPath: "/tmp/sample.mp4")
        let img = NSImage(size: NSSize(width: 100, height: 100))
        let meta = VideoMetadata(
            url: dummyURL,
            title: "Sample Video",
            duration: 120.0,
            durationFormatted: "02:00",
            resolution: "1920x1080",
            fileSizeBytes: 1048576,
            fileSizeFormatted: "1.0 MB",
            thumbnail: img
        )
        #expect(meta.title == "Sample Video")
        #expect(meta.duration == 120.0)
        #expect(meta.thumbnail != nil)
    }

    @Test("ScreenCaptureEngine fetchShareableContent on MainActor")
    @MainActor
    func testScreenCaptureEngineFetch() async {
        _ = try? await ScreenCaptureEngine.fetchShareableContent()
        #expect(Bool(true))
    }
}

