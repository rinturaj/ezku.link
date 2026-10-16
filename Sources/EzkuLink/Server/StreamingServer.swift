import Foundation
import Network
import CryptoKit

public protocol StreamingServerDelegate: AnyObject, Sendable {
    func streamingServer(_ server: StreamingServer, didUpdateClientCount count: Int)
}

public final class StreamingServer: @unchecked Sendable {
    public weak var delegate: StreamingServerDelegate?
    
    public let port: UInt16
    private var listener: NWListener?
    public private(set) var isListening: Bool = false
    private let queue = DispatchQueue(label: "com.ezku.streaming.server", qos: .userInteractive)
    
    // Retain all active client connections (HTTP, WebSocket, MJPEG)
    private var activeConnections: [UUID: ClientConnection] = [:]
    private let connectionsLock = NSLock()
    
    // Video File Streaming with Byte-Range Requests
    private var activeVideoURL: URL?
    private let videoLock = NSLock()
    
    public func setActiveVideoFile(_ url: URL?) {
        videoLock.lock()
        self.activeVideoURL = url
        videoLock.unlock()
    }
    
    public var currentVideoURL: URL? {
        videoLock.lock()
        defer { videoLock.unlock() }
        return activeVideoURL
    }
    
    public init(port: UInt16 = 8765) {
        self.port = port
    }
    
    public func start() throws {
        guard listener == nil else { return }
        
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.noDelay = true
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.allowLocalEndpointReuse = true
        
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw NSError(domain: "StreamingServer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid port: \(port)"])
        }
        
        let newListener = try NWListener(using: parameters, on: nwPort)
        
        // Advertise via Bonjour / mDNS
        newListener.service = NWListener.Service(name: "ezku.link", type: "_ezkulink._tcp")
        
        newListener.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.isListening = true
                print("[StreamingServer] Listening on port \(self.port)")
            case .failed(let error):
                self.isListening = false
                print("[StreamingServer] Listener failed: \(error)")
            case .cancelled:
                self.isListening = false
                print("[StreamingServer] Listener cancelled")
            default:
                break
            }
        }
        
        newListener.newConnectionHandler = { [weak self] connection in
            self?.handleIncomingConnection(connection)
        }
        
        newListener.start(queue: queue)
        self.listener = newListener
    }
    
    public func stop() {
        connectionsLock.lock()
        let clientsToCancel = Array(activeConnections.values)
        activeConnections.removeAll()
        connectionsLock.unlock()
        
        for client in clientsToCancel {
            client.connection.cancel()
        }
        
        listener?.cancel()
        listener = nil
        isListening = false
        notifyClientCount()
    }
    
    private func handleIncomingConnection(_ connection: NWConnection) {
        let clientId = UUID()
        let client = ClientConnection(id: clientId, connection: connection)
        
        // Retain client connection in server dictionary
        connectionsLock.lock()
        activeConnections[clientId] = client
        connectionsLock.unlock()
        
        connection.stateUpdateHandler = { [weak self, weak client] state in
            guard let self = self, let client = client else { return }
            switch state {
            case .ready:
                self.receiveInitialRequest(for: client)
            case .failed, .cancelled:
                self.closeConnection(client.id)
            default:
                break
            }
        }
        
        connection.start(queue: queue)
    }
    
    private func receiveInitialRequest(for client: ClientConnection) {
        client.connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self, weak client] content, _, isComplete, error in
            guard let self = self, let client = client else { return }
            
            if error != nil || isComplete {
                self.closeConnection(client.id)
                return
            }
            
            guard let data = content, !data.isEmpty, let requestString = String(data: data, encoding: .utf8) else {
                self.closeConnection(client.id)
                return
            }
            
            self.handleHTTPRequest(requestString, for: client)
        }
    }
    
    private func handleHTTPRequest(_ requestString: String, for client: ClientConnection) {
        let lines = requestString.components(separatedBy: "\r\n")
        let firstLine = lines.first ?? ""
        let parts = firstLine.split(separator: " ")
        guard parts.count >= 2 else {
            self.closeConnection(client.id)
            return
        }
        
        let method = String(parts[0]).uppercased()
        let rawPath = String(parts[1])
        let path = rawPath.components(separatedBy: "?").first ?? "/"
        
        // Case-insensitive check for WebSocket Upgrade header
        let isWebSocket = requestString.range(of: "upgrade: websocket", options: .caseInsensitive) != nil
            || (requestString.range(of: "upgrade", options: .caseInsensitive) != nil && requestString.range(of: "websocket", options: .caseInsensitive) != nil)
        
        if isWebSocket {
            upgradeToWebSocket(client: client, request: requestString)
        } else if method == "HEAD" {
            handleHeadRequest(client: client, path: path)
        } else if path == "/" || path == "/index.html" {
            serveWebClient(client: client)
        } else if path == "/tv" || path == "/tv/" {
            serveTVClient(client: client)
        } else if path == "/video" || path == "/video/" || path == "/watch" {
            serveVideoPlayer(client: client)
        } else if path == "/media/video" || path == "/video.mp4" || path == "/media/video.mp4" {
            handleVideoFileRequest(client: client, method: method, lines: lines)
        } else if path == "/stream.mjpg" || path == "/tv/stream" || path == "/live.mp4" || path == "/live.mjpg" || (path == "/stream" && !isWebSocket) {
            startMJPEGStream(client: client)
        } else if path == "/status" || path == "/api/status" {
            serveStatus(client: client)
        } else if path == "/favicon.ico" {
            serveFavicon(client: client)
        } else {
            serveNotFound(client: client)
        }
    }

    private func handleHeadRequest(client: ClientConnection, path: String) {
        if path == "/media/video" || path == "/video.mp4" || path == "/media/video.mp4" {
            if let fileURL = currentVideoURL, FileManager.default.fileExists(atPath: fileURL.path) {
                let size = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? UInt64) ?? 0
                let headers = """
                HTTP/1.1 200 OK\r\nContent-Type: video/mp4\r\nContent-Length: \(size)\r\nAccept-Ranges: bytes\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n
                """
                client.connection.send(content: headers.data(using: .utf8), completion: .contentProcessed({ [weak self] _ in
                    self?.closeConnection(client.id)
                }))
                return
            }
        }
        
        let isStreamPath = path.contains("stream") || path.contains("live")
        let headers: String
        if isStreamPath {
            headers = """
            HTTP/1.1 200 OK\r\nContent-Type: video/x-motion-jpeg\r\nConnection: keep-alive\r\nAccess-Control-Allow-Origin: *\r\ncontentFeatures.dlna.org: DLNA.ORG_OP=00;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000\r\nTransferMode.dlna.org: Streaming\r\nServer: ezku.link/1.0 UPnP/1.0 DLNADOC/1.50\r\n\r\n
            """
        } else {
            headers = """
            HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\n\r\n
            """
        }
        client.connection.send(content: headers.data(using: .utf8), completion: .contentProcessed({ [weak self] _ in
            self?.closeConnection(client.id)
        }))
    }
    
    private func serveVideoPlayer(client: ClientConnection) {
        let htmlData = WebClientAssets.videoPage.data(using: .utf8) ?? Data()
        let headers = """
        HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(htmlData.count)\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\n\r\n
        """
        var responseData = headers.data(using: .utf8) ?? Data()
        responseData.append(htmlData)
        client.connection.send(content: responseData, completion: .contentProcessed({ [weak self] _ in
            self?.closeConnection(client.id)
        }))
    }

    private func handleVideoFileRequest(client: ClientConnection, method: String, lines: [String]) {
        guard let fileURL = currentVideoURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            serveNotFound(client: client)
            return
        }
        
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let totalFileSize = attrs[.size] as? UInt64, totalFileSize > 0 else {
            serveNotFound(client: client)
            return
        }
        
        let fileHandle: FileHandle
        do {
            fileHandle = try FileHandle(forReadingFrom: fileURL)
        } catch {
            serveNotFound(client: client)
            return
        }
        
        // Parse Range: bytes=start-end
        var start: UInt64 = 0
        var end: UInt64 = totalFileSize - 1
        var isRangeRequest = false
        
        if let rangeLine = lines.first(where: { $0.lowercased().hasPrefix("range:") }) {
            isRangeRequest = true
            let clean = rangeLine.replacingOccurrences(of: "range:", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "bytes=", with: "", options: .caseInsensitive)
            let parts = clean.split(separator: "-", omittingEmptySubsequences: false)
            if let first = parts.first, let pStart = UInt64(first) {
                start = pStart
            }
            if parts.count > 1, let second = parts.last, !second.isEmpty, let pEnd = UInt64(second) {
                end = min(pEnd, totalFileSize - 1)
            }
        }
        
        if start >= totalFileSize {
            let errorHeader = """
            HTTP/1.1 416 Range Not Satisfiable\r\nContent-Range: bytes */\(totalFileSize)\r\nContent-Length: 0\r\nConnection: close\r\n\r\n
            """
            client.connection.send(content: errorHeader.data(using: .utf8), completion: .contentProcessed({ [weak self] _ in
                try? fileHandle.close()
                self?.closeConnection(client.id)
            }))
            return
        }
        
        let contentLength = (end - start) + 1
        let statusLine = isRangeRequest ? "HTTP/1.1 206 Partial Content" : "HTTP/1.1 200 OK"
        let rangeHeader = isRangeRequest ? "Content-Range: bytes \(start)-\(end)/\(totalFileSize)\r\n" : ""
        
        let headers = """
        \(statusLine)\r\nContent-Type: video/mp4\r\n\(rangeHeader)Content-Length: \(contentLength)\r\nAccept-Ranges: bytes\r\nAccess-Control-Allow-Origin: *\r\nConnection: keep-alive\r\n\r\n
        """
        
        guard let headerData = headers.data(using: .utf8) else {
            try? fileHandle.close()
            closeConnection(client.id)
            return
        }
        
        do {
            try fileHandle.seek(toOffset: start)
        } catch {
            try? fileHandle.close()
            closeConnection(client.id)
            return
        }
        
        client.connection.send(content: headerData, completion: .contentProcessed({ [weak self, weak client] error in
            guard let self = self, let client = client, error == nil else {
                try? fileHandle.close()
                if let id = client?.id { self?.closeConnection(id) }
                return
            }
            self.streamVideoFileChunks(client: client, fileHandle: fileHandle, remainingBytes: contentLength)
        }))
    }
    
    private func streamVideoFileChunks(client: ClientConnection, fileHandle: FileHandle, remainingBytes: UInt64) {
        guard remainingBytes > 0 else {
            try? fileHandle.close()
            return
        }
        
        let chunkSize = Int(min(remainingBytes, 262144)) // 256 KB per chunk
        let data: Data
        do {
            data = try fileHandle.read(upToCount: chunkSize) ?? Data()
        } catch {
            try? fileHandle.close()
            closeConnection(client.id)
            return
        }
        
        guard !data.isEmpty else {
            try? fileHandle.close()
            return
        }
        
        let newRemaining = remainingBytes - UInt64(data.count)
        client.connection.send(content: data, completion: .contentProcessed({ [weak self, weak client] error in
            guard let self = self, let client = client, error == nil else {
                try? fileHandle.close()
                if let id = client?.id { self?.closeConnection(id) }
                return
            }
            self.queue.async {
                self.streamVideoFileChunks(client: client, fileHandle: fileHandle, remainingBytes: newRemaining)
            }
        }))
    }
    
    private func serveWebClient(client: ClientConnection) {
        let htmlData = WebClientAssets.htmlPage.data(using: .utf8) ?? Data()
        let headers = """
        HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(htmlData.count)\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\n\r\n
        """
        
        var responseData = headers.data(using: .utf8) ?? Data()
        responseData.append(htmlData)
        
        client.connection.send(content: responseData, completion: .contentProcessed({ [weak self] _ in
            self?.closeConnection(client.id)
        }))
    }

    private func serveTVClient(client: ClientConnection) {
        let htmlData = WebClientAssets.tvPage.data(using: .utf8) ?? Data()
        let headers = """
        HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(htmlData.count)\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\n\r\n
        """
        
        var responseData = headers.data(using: .utf8) ?? Data()
        responseData.append(htmlData)
        
        client.connection.send(content: responseData, completion: .contentProcessed({ [weak self] _ in
            self?.closeConnection(client.id)
        }))
    }
    
    private func serveStatus(client: ClientConnection) {
        let count = activeClientCount
        let json = "{\"status\":\"ok\",\"server\":\"ezku.link\",\"port\":\(port),\"viewers\":\(count)}\n"
        let jsonData = json.data(using: .utf8) ?? Data()
        let headers = """
        HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(jsonData.count)\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\n\r\n
        """
        var responseData = headers.data(using: .utf8) ?? Data()
        responseData.append(jsonData)
        
        client.connection.send(content: responseData, completion: .contentProcessed({ [weak self] _ in
            self?.closeConnection(client.id)
        }))
    }
    
    private func serveFavicon(client: ClientConnection) {
        let response = "HTTP/1.1 204 No Content\r\nConnection: close\r\n\r\n"
        client.connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ [weak self] _ in
            self?.closeConnection(client.id)
        }))
    }
    
    private func serveNotFound(client: ClientConnection) {
        let notFoundResponse = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        client.connection.send(content: notFoundResponse.data(using: .utf8), completion: .contentProcessed({ [weak self] _ in
            self?.closeConnection(client.id)
        }))
    }

    private func startMJPEGStream(client: ClientConnection) {
        let headers = """
        HTTP/1.1 200 OK\r\nContent-Type: multipart/x-mixed-replace; boundary=--ezkuboundary\r\nConnection: keep-alive\r\nAccess-Control-Allow-Origin: *\r\nCache-Control: no-cache, no-store, must-revalidate\r\ncontentFeatures.dlna.org: DLNA.ORG_OP=00;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000\r\nTransferMode.dlna.org: Streaming\r\nServer: ezku.link/1.0 UPnP/1.0 DLNADOC/1.50\r\n\r\n
        """
        
        client.isMJPEG = true
        client.connection.send(content: headers.data(using: .utf8), completion: .contentProcessed({ [weak self, weak client] error in
            guard let self = self, error == nil, client != nil else {
                if let clientId = client?.id {
                    self?.closeConnection(clientId)
                }
                return
            }
            self.notifyClientCount()
        }))
    }
    
    private func upgradeToWebSocket(client: ClientConnection, request: String) {
        guard let key = extractWebSocketKey(from: request) else {
            closeConnection(client.id)
            return
        }
        
        let magicString = key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        let sha1 = Insecure.SHA1.hash(data: magicString.data(using: .utf8) ?? Data())
        let acceptKey = Data(sha1).base64EncodedString()
        
        let response = """
        HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: \(acceptKey)\r\n\r\n
        """
        
        client.connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ [weak self, weak client] error in
            guard let self = self, let client = client, error == nil else {
                self?.closeConnection(client?.id ?? UUID())
                return
            }
            
            client.isWebSocket = true
            self.notifyClientCount()
            self.listenWebSocketFrames(client: client)
        }))
    }
    
    private func extractWebSocketKey(from request: String) -> String? {
        let lines = request.components(separatedBy: "\r\n")
        for line in lines {
            if line.range(of: "sec-websocket-key:", options: .caseInsensitive) != nil {
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    return parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }
    
    private func listenWebSocketFrames(client: ClientConnection) {
        client.connection.receive(minimumIncompleteLength: 2, maximumLength: 4096) { [weak self, weak client] content, _, isComplete, error in
            guard let self = self, let client = client else { return }
            if error != nil || isComplete {
                self.closeConnection(client.id)
                return
            }
            
            if let data = content, data.count >= 2 {
                let firstByte = data[0]
                let opcode = firstByte & 0x0F
                
                if opcode == 0x08 { // Close frame
                    self.closeConnection(client.id)
                    return
                } else if opcode == 0x09 { // Ping frame -> reply with Pong
                    let pongFrame = self.makeWebSocketPongFrame(from: data)
                    client.connection.send(content: pongFrame, completion: .contentProcessed({ _ in }))
                }
            }
            
            // Continue listening
            self.listenWebSocketFrames(client: client)
        }
    }
    
    private func makeWebSocketPongFrame(from pingData: Data) -> Data {
        var pong = Data()
        pong.append(0x8A) // FIN + Pong opcode (0x0A)
        
        guard pingData.count >= 2 else {
            pong.append(0x00)
            return pong
        }
        
        let maskAndLen = pingData[1]
        let isMasked = (maskAndLen & 0x80) != 0
        let payloadLen = Int(maskAndLen & 0x7F)
        
        if payloadLen == 0 {
            pong.append(0x00)
        } else if isMasked && pingData.count >= 6 + payloadLen {
            let maskKey = pingData[2..<6]
            var unmasked = Data(count: payloadLen)
            for i in 0..<payloadLen {
                unmasked[i] = pingData[6 + i] ^ maskKey[maskKey.startIndex + (i % 4)]
            }
            pong.append(UInt8(payloadLen))
            pong.append(unmasked)
        } else {
            pong.append(0x00)
        }
        return pong
    }
    
    /// Broadcasts a video frame to all connected WebSocket & MJPEG Smart TV clients
    public func broadcastVideoFrame(jpegData: Data, presentationTimeMs: UInt64) {
        // 1. Build WebSocket binary frame payload
        var wsPayload = Data()
        wsPayload.reserveCapacity(9 + jpegData.count)
        wsPayload.append(0x01)
        
        var bigEndianPts = presentationTimeMs.bigEndian
        withUnsafeBytes(of: &bigEndianPts) { wsPayload.append(contentsOf: $0) }
        wsPayload.append(jpegData)
        
        // 2. Build MJPEG multipart frame for Smart TVs
        let mjpegHeader = "--ezkuboundary\r\nContent-Type: image/jpeg\r\nContent-Length: \(jpegData.count)\r\n\r\n"
        var mjpegPayload = mjpegHeader.data(using: .utf8) ?? Data()
        mjpegPayload.append(jpegData)
        mjpegPayload.append("\r\n".data(using: .utf8)!)
        
        connectionsLock.lock()
        let streamingClients = activeConnections.values.filter { $0.isWebSocket || $0.isMJPEG }
        connectionsLock.unlock()
        
        guard !streamingClients.isEmpty else { return }
        
        let wsFrame = makeWebSocketBinaryFrame(payload: wsPayload)
        
        for client in streamingClients {
            guard !client.isSending else { continue }
            client.isSending = true
            
            let frameToSend = client.isMJPEG ? mjpegPayload : wsFrame
            
            client.connection.send(content: frameToSend, completion: .contentProcessed({ [weak self, weak client] error in
                guard let client = client else { return }
                client.isSending = false
                if error != nil {
                    self?.closeConnection(client.id)
                }
            }))
        }
    }
    
    /// Broadcasts an audio packet (16-bit PCM stereo) to all connected clients
    public func broadcastAudioData(pcmData: Data, presentationTimeMs: UInt64) {
        var payload = Data()
        payload.reserveCapacity(9 + pcmData.count)
        payload.append(0x02)
        
        var bigEndianPts = presentationTimeMs.bigEndian
        withUnsafeBytes(of: &bigEndianPts) { payload.append(contentsOf: $0) }
        payload.append(pcmData)
        
        connectionsLock.lock()
        let wsClients = activeConnections.values.filter { $0.isWebSocket }
        connectionsLock.unlock()
        
        guard !wsClients.isEmpty else { return }
        
        let wsFrame = makeWebSocketBinaryFrame(payload: payload)
        
        for client in wsClients {
            guard !client.isSending else { continue }
            client.isSending = true
            
            client.connection.send(content: wsFrame, completion: .contentProcessed({ [weak self, weak client] error in
                guard let client = client else { return }
                client.isSending = false
                if error != nil {
                    self?.closeConnection(client.id)
                }
            }))
        }
    }
    
    private func makeWebSocketBinaryFrame(payload: Data) -> Data {
        var frame = Data()
        let length = payload.count
        
        // FIN = 1, Opcode = 0x2 (Binary Frame)
        frame.append(0x82)
        
        if length < 126 {
            frame.append(UInt8(length))
        } else if length <= 65535 {
            frame.append(126)
            var len16 = UInt16(length).bigEndian
            withUnsafeBytes(of: &len16) { frame.append(contentsOf: $0) }
        } else {
            frame.append(127)
            var len64 = UInt64(length).bigEndian
            withUnsafeBytes(of: &len64) { frame.append(contentsOf: $0) }
        }
        
        frame.append(payload)
        return frame
    }
    
    public func closeConnection(_ id: UUID) {
        connectionsLock.lock()
        let client = activeConnections.removeValue(forKey: id)
        connectionsLock.unlock()
        
        if let client = client {
            client.connection.cancel()
            if client.isWebSocket || client.isMJPEG {
                notifyClientCount()
            }
        }
    }
    
    private func notifyClientCount() {
        let count = activeClientCount
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.streamingServer(self, didUpdateClientCount: count)
        }
    }
    
    public var activeClientCount: Int {
        connectionsLock.lock()
        defer { connectionsLock.unlock() }
        return activeConnections.values.filter { $0.isWebSocket || $0.isMJPEG }.count
    }
}

private final class ClientConnection: @unchecked Sendable {
    let id: UUID
    let connection: NWConnection
    var isWebSocket: Bool = false
    var isMJPEG: Bool = false
    var isSending: Bool = false
    
    init(id: UUID, connection: NWConnection) {
        self.id = id
        self.connection = connection
    }
}
