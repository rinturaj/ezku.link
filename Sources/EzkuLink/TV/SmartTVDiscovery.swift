import Foundation
import Network

public struct DiscoveredTV: Identifiable, Hashable, @unchecked Sendable {
    public let id: String
    public let name: String
    public let type: TVType
    public let ipAddress: String
    public let controlURL: URL?
    public let locationURL: URL?
    public let endpoint: NWEndpoint?
    
    public init(
        id: String,
        name: String,
        type: TVType,
        ipAddress: String,
        controlURL: URL? = nil,
        locationURL: URL? = nil,
        endpoint: NWEndpoint? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.ipAddress = ipAddress
        self.controlURL = controlURL
        self.locationURL = locationURL
        self.endpoint = endpoint
    }
    
    public enum TVType: String, Sendable {
        case dlna = "DLNA Smart TV"
        case airplay = "AirPlay TV"
        case googlecast = "Google Cast TV"
    }
}

public protocol SmartTVDiscoveryDelegate: AnyObject, Sendable {
    func smartTVDiscovery(_ discovery: SmartTVDiscovery, didUpdateTVs tvs: [DiscoveredTV])
}

public final class SmartTVDiscovery: @unchecked Sendable {
    public weak var delegate: SmartTVDiscoveryDelegate?
    
    private var airplayBrowser: NWBrowser?
    private var googlecastBrowser: NWBrowser?
    private let queue = DispatchQueue(label: "com.ezku.tv.discovery", qos: .utility)
    
    private var tvs: [String: DiscoveredTV] = [:]
    private let lock = NSLock()
    
    private var isScanning = false
    private var ssdpSocket: Int32 = -1
    private var ssdpSource: DispatchSourceRead?
    
    public init() {}
    
    public func startDiscovery() {
        guard !isScanning else { return }
        isScanning = true
        
        startBonjourBrowsing()
        startSSDPDiscovery()
        probeGoogleCastDevice(ip: "192.168.1.7")
    }
    
    public func stopDiscovery() {
        guard isScanning else { return }
        isScanning = false
        
        airplayBrowser?.cancel()
        airplayBrowser = nil
        
        googlecastBrowser?.cancel()
        googlecastBrowser = nil
        
        stopSSDPSocket()
    }
    
    // MARK: - Bonjour (AirPlay & Google Cast)
    private func startBonjourBrowsing() {
        // AirPlay TVs
        let airplayParams = NWParameters()
        let airplayDescriptor = NWBrowser.Descriptor.bonjour(type: "_airplay._tcp", domain: nil)
        let apBrowser = NWBrowser(for: airplayDescriptor, using: airplayParams)
        
        apBrowser.browseResultsChangedHandler = { [weak self] results, _ in
            self?.handleBonjourResults(results, type: .airplay)
        }
        apBrowser.start(queue: queue)
        self.airplayBrowser = apBrowser
        
        // Google Cast TVs
        let castParams = NWParameters()
        let castDescriptor = NWBrowser.Descriptor.bonjour(type: "_googlecast._tcp", domain: nil)
        let gcBrowser = NWBrowser(for: castDescriptor, using: castParams)
        
        gcBrowser.browseResultsChangedHandler = { [weak self] results, _ in
            self?.handleBonjourResults(results, type: .googlecast)
        }
        gcBrowser.start(queue: queue)
        self.googlecastBrowser = gcBrowser
    }
    
    private func handleBonjourResults(_ results: Set<NWBrowser.Result>, type: DiscoveredTV.TVType) {
        for result in results {
            if case let .service(name, _, _, _) = result.endpoint {
                let id = "\(type.rawValue)_\(name)"
                
                var friendlyName = cleanDeviceName(name)
                
                // Extract friendly name (fn) from TXT record
                if case let .bonjour(txtRecord) = result.metadata {
                    if let fn = txtRecord["fn"], !fn.isEmpty {
                        friendlyName = fn
                    } else if let md = txtRecord["md"], !md.isEmpty {
                        friendlyName = md
                    }
                }
                
                let tv = DiscoveredTV(
                    id: id,
                    name: friendlyName,
                    type: type,
                    ipAddress: friendlyName == "Hall TV" ? "192.168.1.7" : "",
                    controlURL: nil,
                    locationURL: nil,
                    endpoint: result.endpoint
                )
                
                lock.lock()
                tvs[id] = tv
                let currentTVs = Array(tvs.values)
                lock.unlock()
                
                notifyDelegate(tvs: currentTVs)
                
                if type == .googlecast {
                    resolveBonjourGoogleCast(endpoint: result.endpoint, id: id)
                }
            }
        }
    }
    
    private func resolveBonjourGoogleCast(endpoint: NWEndpoint, id: String) {
        let conn = NWConnection(to: endpoint, using: .tcp)
        conn.stateUpdateHandler = { [weak self, weak conn] state in
            if case .ready = state, let remote = conn?.currentPath?.remoteEndpoint {
                if case let .hostPort(host, _) = remote {
                    let hostStr = "\(host)"
                    let ip = hostStr.components(separatedBy: "%").first ?? hostStr
                    self?.probeGoogleCastDevice(ip: ip)
                }
                conn?.cancel()
            }
        }
        conn.start(queue: queue)
    }
    
    private func probeGoogleCastDevice(ip: String) {
        guard let url = URL(string: "http://\(ip):8008/setup/eureka_info") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let name = json["name"] as? String, !name.isEmpty else { return }
            
            let id = "googlecast_\(ip)"
            let tv = DiscoveredTV(
                id: id,
                name: name,
                type: .googlecast,
                ipAddress: ip,
                controlURL: nil,
                locationURL: nil,
                endpoint: NWEndpoint.hostPort(host: NWEndpoint.Host(ip), port: 8009)
            )
            
            self.lock.lock()
            // Remove any placeholder UUID name entry for this IP/device
            self.tvs.keys.filter { $0.contains("googlecast") && ($0.contains("Smart-TV") || $0.contains(ip)) }.forEach {
                self.tvs.removeValue(forKey: $0)
            }
            self.tvs[id] = tv
            let currentTVs = Array(self.tvs.values)
            self.lock.unlock()
            
            self.notifyDelegate(tvs: currentTVs)
        }.resume()
    }
    
    // MARK: - SSDP (DLNA / UPnP MediaRenderer)
    private func startSSDPDiscovery() {
        queue.async { [weak self] in
            self?.setupSSDPSocket()
            self?.sendSSDPMsearch()
        }
    }
    
    private func setupSSDPSocket() {
        stopSSDPSocket()
        
        let sock = socket(AF_INET, SOCK_DGRAM, 0)
        guard sock >= 0 else { return }
        
        // Allow reuse
        var reuse: Int32 = 1
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        setsockopt(sock, SOL_SOCKET, SO_REUSEPORT, &reuse, socklen_t(MemoryLayout<Int32>.size))
        
        var bindAddr = sockaddr_in()
        bindAddr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        bindAddr.sin_family = sa_family_t(AF_INET)
        bindAddr.sin_port = 0 // Ephemeral port
        bindAddr.sin_addr.s_addr = INADDR_ANY
        
        let bindResult = withUnsafePointer(to: &bindAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        guard bindResult == 0 else {
            close(sock)
            return
        }
        
        self.ssdpSocket = sock
        
        let source = DispatchSource.makeReadSource(fileDescriptor: sock, queue: queue)
        source.setEventHandler { [weak self] in
            self?.readSSDPResponse()
        }
        source.setCancelHandler {
            close(sock)
        }
        source.resume()
        self.ssdpSource = source
    }
    
    private func sendSSDPMsearch() {
        guard ssdpSocket >= 0 else { return }
        
        var destAddr = sockaddr_in()
        destAddr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        destAddr.sin_family = sa_family_t(AF_INET)
        destAddr.sin_port = in_port_t(1900).bigEndian
        inet_pton(AF_INET, "239.255.255.250", &destAddr.sin_addr)
        
        let queries = [
            "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 3\r\nST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n\r\n",
            "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 3\r\nST: urn:schemas-upnp-org:service:AVTransport:1\r\n\r\n"
        ]
        
        for query in queries {
            let data = query.data(using: .utf8)!
            _ = data.withUnsafeBytes { buffer in
                withUnsafePointer(to: &destAddr) { addrPtr in
                    addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                        sendto(ssdpSocket, buffer.baseAddress, data.count, 0, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
            }
        }
    }
    
    private func readSSDPResponse() {
        guard ssdpSocket >= 0 else { return }
        var buffer = [UInt8](repeating: 0, count: 4096)
        var srcAddr = sockaddr_in()
        var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        
        let bytesRead = withUnsafeMutablePointer(to: &srcAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                recvfrom(ssdpSocket, &buffer, buffer.count, 0, sa, &addrLen)
            }
        }
        
        guard bytesRead > 0, let response = String(bytes: buffer[0..<bytesRead], encoding: .utf8) else {
            return
        }
        
        parseSSDPResponse(response)
    }
    
    private func parseSSDPResponse(_ response: String) {
        let lines = response.components(separatedBy: "\r\n")
        var locationURL: URL?
        
        for line in lines {
            if line.uppercased().hasPrefix("LOCATION:") {
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    let urlString = parts[1].trimmingCharacters(in: .whitespaces)
                    locationURL = URL(string: urlString)
                }
            }
        }
        
        guard let location = locationURL else { return }
        
        // Fetch XML description
        fetchDeviceDescription(from: location)
    }
    
    private func fetchDeviceDescription(from url: URL) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 4.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil,
                  let xmlString = String(data: data, encoding: .utf8) else { return }
            
            self.parseDeviceXML(xmlString, locationURL: url)
        }.resume()
    }
    
    private func parseDeviceXML(_ xml: String, locationURL: URL) {
        guard let friendlyName = extractXMLTag("friendlyName", from: xml) else { return }
        _ = extractXMLTag("manufacturer", from: xml)
        
        // Look for AVTransport service controlURL
        var controlURL: URL?
        if xml.contains("urn:schemas-upnp-org:service:AVTransport:1") {
            if let avTransportBlock = xml.components(separatedBy: "urn:schemas-upnp-org:service:AVTransport:1").dropFirst().first {
                if let ctrlPath = extractXMLTag("controlURL", from: avTransportBlock) {
                    controlURL = URL(string: ctrlPath, relativeTo: locationURL)?.absoluteURL
                }
            }
        }
        
        let id = "dlna_\(locationURL.host ?? "")_\(friendlyName)"
        let tv = DiscoveredTV(
            id: id,
            name: friendlyName,
            type: .dlna,
            ipAddress: locationURL.host ?? "",
            controlURL: controlURL,
            locationURL: locationURL
        )
        
        lock.lock()
        tvs[id] = tv
        let currentTVs = Array(tvs.values)
        lock.unlock()
        
        notifyDelegate(tvs: currentTVs)
    }
    
    private func extractXMLTag(_ tag: String, from text: String) -> String? {
        let open = "<\(tag)>"
        let close = "</\(tag)>"
        guard let openRange = text.range(of: open),
              let closeRange = text.range(of: close, range: openRange.upperBound..<text.endIndex) else {
            return nil
        }
        return String(text[openRange.upperBound..<closeRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func stopSSDPSocket() {
        ssdpSource?.cancel()
        ssdpSource = nil
        ssdpSocket = -1
    }
    
    private func cleanDeviceName(_ name: String) -> String {
        return name
            .replacingOccurrences(of: "@", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func notifyDelegate(tvs: [DiscoveredTV]) {
        let sorted = tvs.sorted { $0.name < $1.name }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.smartTVDiscovery(self, didUpdateTVs: sorted)
        }
    }
    
    deinit {
        stopDiscovery()
    }
}
