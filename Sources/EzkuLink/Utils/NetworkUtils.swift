import Foundation
import CoreImage
import AppKit

public enum NetworkUtils {
    /// Returns the primary local IPv4 address of the Mac (e.g., 192.168.1.50)
    public static func getLocalIPAddress() -> String {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return "127.0.0.1"
        }
        defer { freeifaddrs(ifaddr) }
        
        var en0Address: String?
        var anyIPv4Address: String?
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            // Check for IPv4
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                let flags = Int32(interface.ifa_flags)
                let isUp = (flags & IFF_UP) != 0
                let isLoopback = (flags & IFF_LOOPBACK) != 0
                
                if isUp && !isLoopback {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(interface.ifa_addr,
                                   socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname,
                                   socklen_t(hostname.count),
                                   nil,
                                   0,
                                   NI_NUMERICHOST) == 0 {
                        let ip = hostname.withUnsafeBufferPointer { ptr in
                            ptr.baseAddress.map { String(cString: $0) } ?? ""
                        }
                        if !ip.isEmpty {
                            if name == "en0" {
                                en0Address = ip
                            } else if anyIPv4Address == nil {
                                anyIPv4Address = ip
                            }
                        }
                    }
                }
            }
        }
        
        return en0Address ?? anyIPv4Address ?? "127.0.0.1"
    }
    
    /// Generates a crisp NSImage of a QR Code for the given string
    public static func generateQRCode(from string: String, size: CGFloat = 200) -> NSImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Medium error correction
        
        guard let outputCIImage = filter.outputImage else { return nil }
        
        // Scale to crisp resolution without blur
        let extent = outputCIImage.extent
        let scale = size / extent.width
        let transformedImage = outputCIImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        let rep = NSCIImageRep(ciImage: transformedImage)
        let nsImage = NSImage(size: NSSize(width: size, height: size))
        nsImage.addRepresentation(rep)
        return nsImage
    }
}
