import Foundation

public enum DLNAError: LocalizedError {
    case invalidControlURL
    case networkError(String)
    case tvRejected(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidControlURL:
            return "Invalid TV control URL"
        case .networkError(let msg):
            return "Network error contacting TV: \(msg)"
        case .tvRejected(let msg):
            return "TV rejected playback request: \(msg)"
        }
    }
}

public final class DLNAController: Sendable {
    public static let shared = DLNAController()
    
    private init() {}
    
    /// Commands the Smart TV to load the live casting URL and start playback
    public func castStream(to tv: DiscoveredTV, streamURL: String) async throws {
        guard let controlURL = tv.controlURL else {
            throw DLNAError.invalidControlURL
        }
        
        // Step 1: Stop any currently playing media
        _ = try? await sendSOAP(action: "Stop", body: stopBody(), to: controlURL)
        
        // Step 2: Set AVTransport URI
        let setURIBody = setAVTransportURIBody(streamURL: streamURL, title: "ezku.link Mac Screen")
        try await sendSOAP(action: "SetAVTransportURI", body: setURIBody, to: controlURL)
        
        // Step 3: Send Play command
        try await sendSOAP(action: "Play", body: playBody(), to: controlURL)
    }
    
    /// Stops playback on the Smart TV
    public func stopStream(on tv: DiscoveredTV) async throws {
        guard let controlURL = tv.controlURL else { return }
        try await sendSOAP(action: "Stop", body: stopBody(), to: controlURL)
    }
    
    /// Commands the Smart TV to load a video file and start playback
    public func castVideo(to tv: DiscoveredTV, videoURL: String, title: String) async throws {
        guard let controlURL = tv.controlURL else {
            throw DLNAError.invalidControlURL
        }
        _ = try? await sendSOAP(action: "Stop", body: stopBody(), to: controlURL)
        let setURIBody = setAVTransportURIBody(streamURL: videoURL, title: title)
        try await sendSOAP(action: "SetAVTransportURI", body: setURIBody, to: controlURL)
        try await sendSOAP(action: "Play", body: playBody(), to: controlURL)
    }
    
    public func pauseVideo(on tv: DiscoveredTV) async throws {
        guard let controlURL = tv.controlURL else { return }
        let body = "<u:Pause xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\"><InstanceID>0</InstanceID></u:Pause>"
        try await sendSOAP(action: "Pause", body: body, to: controlURL)
    }
    
    public func playVideo(on tv: DiscoveredTV) async throws {
        guard let controlURL = tv.controlURL else { return }
        try await sendSOAP(action: "Play", body: playBody(), to: controlURL)
    }
    
    public func seekVideo(on tv: DiscoveredTV, to seconds: Double) async throws {
        guard let controlURL = tv.controlURL else { return }
        let total = Int(seconds)
        let s = total % 60
        let m = (total / 60) % 60
        let h = total / 3600
        let target = String(format: "%02d:%02d:%02d", h, m, s)
        let body = """
        <u:Seek xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
            <Unit>REL_TIME</Unit>
            <Target>\(target)</Target>
        </u:Seek>
        """
        try await sendSOAP(action: "Seek", body: body, to: controlURL)
    }
    
    // MARK: - SOAP Network Request
    private func sendSOAP(action: String, body: String, to controlURL: URL) async throws {
        var request = URLRequest(url: controlURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
        request.setValue("\"urn:schemas-upnp-org:service:AVTransport:1#\(action)\"", forHTTPHeaderField: "SOAPACTION")
        
        let envelope = """
        <?xml version="1.0" encoding="utf-8"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
            <s:Body>
                \(body)
            </s:Body>
        </s:Envelope>
        """
        request.httpBody = envelope.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpRes = response as? HTTPURLResponse, httpRes.statusCode >= 400 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpRes.statusCode)"
            throw DLNAError.tvRejected(errorMsg)
        }
    }
    
    // MARK: - SOAP Payloads
    private func setAVTransportURIBody(streamURL: String, title: String) -> String {
        let didl = """
        &lt;DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/"&gt;&lt;item id="0" parentID="-1" restricted="1"&gt;&lt;dc:title&gt;\(title)&lt;/dc:title&gt;&lt;upnp:class&gt;object.item.videoItem&lt;/upnp:class&gt;&lt;res protocolInfo="http-get:*:video/x-motion-jpeg:DLNA.ORG_OP=00;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000"&gt;\(streamURL)&lt;/res&gt;&lt;res protocolInfo="http-get:*:multipart/x-mixed-replace:*"&gt;\(streamURL)&lt;/res&gt;&lt;res protocolInfo="http-get:*:video/mp4:*"&gt;\(streamURL)&lt;/res&gt;&lt;res protocolInfo="http-get:*:image/jpeg:DLNA.ORG_PN=JPEG_LRG;DLNA.ORG_OP=00;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000"&gt;\(streamURL)&lt;/res&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;
        """
        
        return """
        <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
            <CurrentURI>\(streamURL)</CurrentURI>
            <CurrentURIMetaData>\(didl)</CurrentURIMetaData>
        </u:SetAVTransportURI>
        """
    }
    
    private func playBody() -> String {
        return """
        <u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
            <Speed>1</Speed>
        </u:Play>
        """
    }
    
    private func stopBody() -> String {
        return """
        <u:Stop xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
        </u:Stop>
        """
    }
}
