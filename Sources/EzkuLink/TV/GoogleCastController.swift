import Foundation
import Network

public enum GoogleCastError: LocalizedError {
    case connectionFailed(String)
    case appLaunchFailed(String)
    case deviceNotReady
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "Google Cast connection failed: \(msg)"
        case .appLaunchFailed(let msg): return "Could not launch app on TV: \(msg)"
        case .deviceNotReady: return "Google Cast device not ready"
        case .timeout: return "Google Cast request timed out"
        }
    }
}

public protocol GoogleCastControllerDelegate: AnyObject, Sendable {
    func googleCastController(_ controller: GoogleCastController, didUpdateMediaStatus isPlaying: Bool, currentTime: Double, duration: Double)
}

private final class CastStateBox: @unchecked Sendable {
    private let lock = NSLock()
    private var transportId: String?
    private var sessionId: String?
    private var mediaSessionId: Int?
    private var isPlaying: Bool = false
    private var currentTime: Double = 0.0
    private var duration: Double = 0.0
    
    func update(transportId: String, sessionId: String) {
        lock.lock()
        defer { lock.unlock() }
        self.transportId = transportId
        self.sessionId = sessionId
    }
    
    func updateMediaStatus(mediaSessionId: Int?, isPlaying: Bool?, currentTime: Double?, duration: Double?) -> (isPlaying: Bool, currentTime: Double, duration: Double)? {
        lock.lock()
        defer { lock.unlock() }
        if let msId = mediaSessionId { self.mediaSessionId = msId }
        if let playing = isPlaying { self.isPlaying = playing }
        if let cur = currentTime { self.currentTime = cur }
        if let dur = duration, dur > 0 { self.duration = dur }
        return (self.isPlaying, self.currentTime, self.duration)
    }
    
    func current() -> (transportId: String?, sessionId: String?) {
        lock.lock()
        defer { lock.unlock() }
        return (transportId, sessionId)
    }
    
    func currentMediaInfo() -> (transportId: String?, sessionId: String?, mediaSessionId: Int?) {
        lock.lock()
        defer { lock.unlock() }
        return (transportId, sessionId, mediaSessionId)
    }
    
    func clear() -> (transportId: String?, sessionId: String?) {
        lock.lock()
        defer { lock.unlock() }
        let prev = (transportId, sessionId)
        transportId = nil
        sessionId = nil
        mediaSessionId = nil
        isPlaying = false
        currentTime = 0.0
        duration = 0.0
        return prev
    }
}

private final class AtomicContinuationGate: @unchecked Sendable {
    private let lock = NSLock()
    private var resumed = false
    
    func runOnce(_ block: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard !resumed else { return }
        resumed = true
        block()
    }
}

public final class GoogleCastController: @unchecked Sendable {
    public static let shared = GoogleCastController()
    public weak var delegate: GoogleCastControllerDelegate?
    
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.ezku.tv.googlecast", qos: .userInteractive)
    private let stateBox = CastStateBox()
    private var heartbeatTimer: DispatchSourceTimer?
    private let connLock = NSLock()
    
    // Official URL Cast Receiver app ID for Google Cast
    public static let urlCastAppId = "5CB45E5A"
    // Official Default Media Receiver app ID for Google Cast (video streaming)
    public static let defaultMediaReceiverAppId = "CC1AD845"
    
    private init() {}
    
    private func setConnection(_ conn: NWConnection?) {
        connLock.lock()
        self.connection = conn
        connLock.unlock()
    }
    
    private func getAndClearConnection() -> NWConnection? {
        connLock.lock()
        let conn = self.connection
        self.connection = nil
        connLock.unlock()
        return conn
    }
    
    private func establishConnection(to targetEndpoint: NWEndpoint) async throws -> NWConnection {
        let tlsOptions = NWProtocolTLS.Options()
        sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { _, _, sec_protocol_verify_complete in
            sec_protocol_verify_complete(true)
        }, queue)
        
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.noDelay = true
        let params = NWParameters(tls: tlsOptions, tcp: tcpOptions)
        
        let conn = NWConnection(to: targetEndpoint, using: params)
        setConnection(conn)
        
        let gate = AtomicContinuationGate()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    gate.runOnce { continuation.resume() }
                case .failed(let err):
                    gate.runOnce { continuation.resume(throwing: GoogleCastError.connectionFailed(err.localizedDescription)) }
                default:
                    break
                }
            }
            conn.start(queue: queue)
        }
        
        startReadingMessages(conn)
        startHeartbeat(conn)
        return conn
    }
    
    /// Connects to a Google Cast TV and launches the web casting player
    public func cast(to tv: DiscoveredTV, tvWebURL: String) async throws {
        disconnect()
        
        let targetHost = tv.ipAddress.isEmpty ? "192.168.1.7" : tv.ipAddress
        let targetEndpoint = tv.endpoint ?? NWEndpoint.hostPort(host: NWEndpoint.Host(targetHost), port: 8009)
        
        print("[GoogleCast] Connecting to \(tv.name)...")
        let conn = try await establishConnection(to: targetEndpoint)
        
        // Step 1: Connect to receiver-0
        let connectMsg = Self.makeCastMessage(
            sourceId: "sender-0",
            destId: "receiver-0",
            namespace: "urn:x-cast:com.google.cast.tp.connection",
            payload: "{\"type\":\"CONNECT\"}"
        )
        try await sendData(connectMsg, on: conn)
        
        // Step 2: Launch URL Cast Receiver (appId 5CB45E5A)
        print("[GoogleCast] Launching URL Cast Receiver on \(tv.name)...")
        let launchMsg = Self.makeCastMessage(
            sourceId: "sender-0",
            destId: "receiver-0",
            namespace: "urn:x-cast:com.google.cast.receiver",
            payload: "{\"type\":\"LAUNCH\",\"appId\":\"\(Self.urlCastAppId)\",\"requestId\":1}"
        )
        try await sendData(launchMsg, on: conn)
        
        // Step 3: Wait for transportId to be resolved via incoming RECEIVER_STATUS
        let (transportId, sessionId) = try await waitForAppLaunch(timeoutSeconds: 8.0)
        print("[GoogleCast] URL Cast running with transportId: \(transportId), sessionId: \(sessionId)")
        
        // Step 4: Connect to URL Cast Receiver transport
        let appConnect = Self.makeCastMessage(
            sourceId: "sender-0",
            destId: transportId,
            namespace: "urn:x-cast:com.google.cast.tp.connection",
            payload: "{\"type\":\"CONNECT\"}"
        )
        try await sendData(appConnect, on: conn)
        
        // Step 5: Send target /tv URL to URL Cast Receiver
        print("[GoogleCast] Directing TV to \(tvWebURL)...")
        let urlPayload = "{\"type\":\"loc\",\"url\":\"\(tvWebURL)\"}"
        let urlMsg = Self.makeCastMessage(
            sourceId: "sender-0",
            destId: transportId,
            namespace: "urn:x-cast:com.url.cast",
            payload: urlPayload
        )
        try await sendData(urlMsg, on: conn)
        print("[GoogleCast] Successfully casted to \(tv.name)!")
    }
    
    /// Connects to a Google Cast TV and launches the Default Media Receiver (CC1AD845) to stream a video file directly
    public func castVideo(to tv: DiscoveredTV, videoURL: String, title: String) async throws {
        disconnect()
        
        let targetHost = tv.ipAddress.isEmpty ? "192.168.1.7" : tv.ipAddress
        let targetEndpoint = tv.endpoint ?? NWEndpoint.hostPort(host: NWEndpoint.Host(targetHost), port: 8009)
        
        print("[GoogleCast] Connecting to \(tv.name) for video streaming...")
        let conn = try await establishConnection(to: targetEndpoint)
        
        // Step 1: Connect to receiver-0
        let connectMsg = Self.makeCastMessage(
            sourceId: "sender-0",
            destId: "receiver-0",
            namespace: "urn:x-cast:com.google.cast.tp.connection",
            payload: "{\"type\":\"CONNECT\"}"
        )
        try await sendData(connectMsg, on: conn)
        
        // Step 2: Launch Default Media Receiver (appId CC1AD845)
        print("[GoogleCast] Launching Default Media Receiver on \(tv.name)...")
        let launchMsg = Self.makeCastMessage(
            sourceId: "sender-0",
            destId: "receiver-0",
            namespace: "urn:x-cast:com.google.cast.receiver",
            payload: "{\"type\":\"LAUNCH\",\"appId\":\"\(Self.defaultMediaReceiverAppId)\",\"requestId\":1}"
        )
        try await sendData(launchMsg, on: conn)
        
        // Step 3: Wait for transportId
        let (transportId, sessionId) = try await waitForAppLaunch(timeoutSeconds: 8.0)
        print("[GoogleCast] Default Media Receiver running with transportId: \(transportId)")
        
        // Step 4: Connect to media receiver transport
        let appConnect = Self.makeCastMessage(
            sourceId: "sender-0",
            destId: transportId,
            namespace: "urn:x-cast:com.google.cast.tp.connection",
            payload: "{\"type\":\"CONNECT\"}"
        )
        try await sendData(appConnect, on: conn)
        
        // Step 5: Send LOAD command with video URL
        print("[GoogleCast] Sending video LOAD: \(videoURL)...")
        let safeTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let loadPayload = """
        {"type":"LOAD","requestId":2,"sessionId":"\(sessionId)","media":{"contentId":"\(videoURL)","streamType":"BUFFERED","contentType":"video/mp4","metadata":{"metadataType":0,"title":"\(safeTitle)"}},"autoplay":true,"currentTime":0}
        """
        let loadMsg = Self.makeCastMessage(
            sourceId: "sender-0",
            destId: transportId,
            namespace: "urn:x-cast:com.google.cast.media",
            payload: loadPayload
        )
        try await sendData(loadMsg, on: conn)
        print("[GoogleCast] Video streaming active on \(tv.name)!")
        
        // Request initial media status
        let statusPayload = "{\"type\":\"GET_STATUS\",\"requestId\":3}"
        let statusMsg = Self.makeCastMessage(sourceId: "sender-0", destId: transportId, namespace: "urn:x-cast:com.google.cast.media", payload: statusPayload)
        try? await sendData(statusMsg, on: conn)
    }
    
    public func pauseMedia() async throws {
        let (tId, _, mId) = stateBox.currentMediaInfo()
        guard let transportId = tId, let conn = connection else { return }
        let reqId = Int.random(in: 100...999)
        var dict: [String: Any] = ["type": "PAUSE", "requestId": reqId]
        if let msId = mId { dict["mediaSessionId"] = msId }
        if let data = try? JSONSerialization.data(withJSONObject: dict), let json = String(data: data, encoding: .utf8) {
            let msg = Self.makeCastMessage(sourceId: "sender-0", destId: transportId, namespace: "urn:x-cast:com.google.cast.media", payload: json)
            try await sendData(msg, on: conn)
        }
    }
    
    public func playMedia() async throws {
        let (tId, _, mId) = stateBox.currentMediaInfo()
        guard let transportId = tId, let conn = connection else { return }
        let reqId = Int.random(in: 100...999)
        var dict: [String: Any] = ["type": "PLAY", "requestId": reqId]
        if let msId = mId { dict["mediaSessionId"] = msId }
        if let data = try? JSONSerialization.data(withJSONObject: dict), let json = String(data: data, encoding: .utf8) {
            let msg = Self.makeCastMessage(sourceId: "sender-0", destId: transportId, namespace: "urn:x-cast:com.google.cast.media", payload: json)
            try await sendData(msg, on: conn)
        }
    }
    
    public func seekMedia(to seconds: Double) async throws {
        let (tId, _, mId) = stateBox.currentMediaInfo()
        guard let transportId = tId, let conn = connection else { return }
        let reqId = Int.random(in: 100...999)
        var dict: [String: Any] = [
            "type": "SEEK",
            "requestId": reqId,
            "currentTime": seconds,
            "resumeState": "PLAYBACK_START"
        ]
        if let msId = mId { dict["mediaSessionId"] = msId }
        if let data = try? JSONSerialization.data(withJSONObject: dict), let json = String(data: data, encoding: .utf8) {
            let msg = Self.makeCastMessage(sourceId: "sender-0", destId: transportId, namespace: "urn:x-cast:com.google.cast.media", payload: json)
            try await sendData(msg, on: conn)
        }
    }
    
    /// Stops casting on the TV and closes the receiver app
    public func disconnect() {
        let conn = getAndClearConnection()
        
        let prev = stateBox.clear()
        stopHeartbeat()
        
        guard let conn = conn else { return }
        
        if let sessionId = prev.sessionId {
            let stopMsg = Self.makeCastMessage(
                sourceId: "sender-0",
                destId: "receiver-0",
                namespace: "urn:x-cast:com.google.cast.receiver",
                payload: "{\"type\":\"STOP\",\"sessionId\":\"\(sessionId)\",\"requestId\":99}"
            )
            conn.send(content: stopMsg, completion: .contentProcessed { _ in
                conn.cancel()
            })
        } else {
            conn.cancel()
        }
    }
    
    private func waitForAppLaunch(timeoutSeconds: Double) async throws -> (transportId: String, sessionId: String) {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            let state = stateBox.current()
            if let tId = state.transportId, let sId = state.sessionId, !tId.isEmpty, !sId.isEmpty {
                return (tId, sId)
            }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        throw GoogleCastError.timeout
    }
    
    private func startReadingMessages(_ conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 4, maximumLength: 65536) { [weak self, weak conn] content, _, isComplete, error in
            guard let self = self, let conn = conn, error == nil, !isComplete else {
                return
            }
            
            if let data = content, data.count > 4 {
                let payloadData = data.dropFirst(4)
                let payloadString = String(data: payloadData, encoding: .utf8)
                    ?? payloadData.map { ($0 >= 32 && $0 <= 126) ? String(UnicodeScalar($0)) : " " }.joined()
                
                self.handleIncomingCastString(payloadString)
            }
            
            self.startReadingMessages(conn)
        }
    }
    
    private func handleIncomingCastString(_ str: String) {
        // App launch resolution (URL Cast or Default Media Receiver)
        let matchesApp = str.contains(Self.urlCastAppId) || str.contains(Self.defaultMediaReceiverAppId) || str.contains("transportId")
        if matchesApp && str.contains("\"transportId\":\"") {
            if let transportRange = str.range(of: "\"transportId\":\"") {
                let rest = str[transportRange.upperBound...]
                if let end = rest.range(of: "\"") {
                    let transportId = String(rest[..<end.lowerBound])
                    
                    var sessionId = transportId
                    if let sessRange = str.range(of: "\"sessionId\":\"") {
                        let sessRest = str[sessRange.upperBound...]
                        if let sessEnd = sessRest.range(of: "\"") {
                            sessionId = String(sessRest[..<sessEnd.lowerBound])
                        }
                    }
                    
                    stateBox.update(transportId: transportId, sessionId: sessionId)
                }
            }
        }
        
        // Media status updates
        if str.contains("MEDIA_STATUS") {
            var mediaSessionId: Int? = nil
            var isPlaying: Bool? = nil
            var currentTime: Double? = nil
            var duration: Double? = nil
            
            if let msIdRange = str.range(of: "\"mediaSessionId\":") {
                let rest = str[msIdRange.upperBound...].trimmingCharacters(in: .whitespaces)
                let numStr = rest.prefix(while: { $0.isNumber })
                mediaSessionId = Int(numStr)
            }
            
            if let stateRange = str.range(of: "\"playerState\":\"") {
                let rest = str[stateRange.upperBound...]
                if let end = rest.range(of: "\"") {
                    let playerState = String(rest[..<end.lowerBound])
                    isPlaying = (playerState == "PLAYING" || playerState == "BUFFERING")
                }
            }
            
            if let timeRange = str.range(of: "\"currentTime\":") {
                let rest = str[timeRange.upperBound...].trimmingCharacters(in: .whitespaces)
                let numStr = rest.prefix(while: { $0.isNumber || $0 == "." })
                currentTime = Double(numStr)
            }
            
            if let durRange = str.range(of: "\"duration\":") {
                let rest = str[durRange.upperBound...].trimmingCharacters(in: .whitespaces)
                let numStr = rest.prefix(while: { $0.isNumber || $0 == "." })
                duration = Double(numStr)
            }
            
            if let updated = stateBox.updateMediaStatus(mediaSessionId: mediaSessionId, isPlaying: isPlaying, currentTime: currentTime, duration: duration) {
                delegate?.googleCastController(self, didUpdateMediaStatus: updated.isPlaying, currentTime: updated.currentTime, duration: updated.duration)
            }
        }
    }
    
    private func startHeartbeat(_ conn: NWConnection) {
        stopHeartbeat()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 4.0, repeating: 4.0)
        timer.setEventHandler { [weak conn] in
            guard let conn = conn else { return }
            let pingMsg = GoogleCastController.makeCastMessage(
                sourceId: "sender-0",
                destId: "receiver-0",
                namespace: "urn:x-cast:com.google.cast.tp.heartbeat",
                payload: "{\"type\":\"PING\"}"
            )
            conn.send(content: pingMsg, completion: .contentProcessed { _ in })
        }
        timer.resume()
        self.heartbeatTimer = timer
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }
    
    private func sendData(_ data: Data, on conn: NWConnection) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            conn.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
    // MARK: - Protobuf Serialization (CastMessage)
    public static func makeCastMessage(
        sourceId: String,
        destId: String,
        namespace: String,
        payload: String
    ) -> Data {
        var body = Data()
        body.append(contentsOf: [0x08, 0x00])
        body.append(encodeStringField(fieldNumber: 2, value: sourceId))
        body.append(encodeStringField(fieldNumber: 3, value: destId))
        body.append(encodeStringField(fieldNumber: 4, value: namespace))
        body.append(contentsOf: [0x28, 0x00])
        body.append(encodeStringField(fieldNumber: 6, value: payload))
        
        var frame = Data()
        var len = UInt32(body.count).bigEndian
        withUnsafeBytes(of: &len) { frame.append(contentsOf: $0) }
        frame.append(body)
        return frame
    }
    
    private static func encodeStringField(fieldNumber: Int, value: String) -> Data {
        let bytes = value.data(using: .utf8) ?? Data()
        var d = Data([UInt8((fieldNumber << 3) | 2)])
        d.append(encodeVarint(bytes.count))
        d.append(bytes)
        return d
    }
    
    private static func encodeVarint(_ value: Int) -> Data {
        var v = value
        var d = Data()
        while v >= 0x80 {
            d.append(UInt8((v & 0x7F) | 0x80))
            v >>= 7
        }
        d.append(UInt8(v))
        return d
    }
}
