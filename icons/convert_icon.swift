import Foundation
import AppKit
import CoreGraphics

let inputPath = "/Users/rinturajc/FrontEnd/ezkuCasting/icons/appicon_new.jpg"
let outputTightPath = "/Users/rinturajc/FrontEnd/ezkuCasting/icons/appicon_tight.png"
let outputAppIconPng = "/Users/rinturajc/FrontEnd/ezkuCasting/Resources/AppIcon.png"
let iconsetDir = "/Users/rinturajc/FrontEnd/ezkuCasting/icons/AppIcon.iconset"
let outputIcns = "/Users/rinturajc/FrontEnd/ezkuCasting/Resources/AppIcon.icns"

guard let img = NSImage(contentsOfFile: inputPath),
      let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Error: Could not load \(inputPath)")
    exit(1)
}

let origW = cgImage.width
let origH = cgImage.height
print("Source image size: \(origW) x \(origH)")

// Find the exact non-black squircle bounding box
let tempColorSpace = CGColorSpaceCreateDeviceRGB()
let tempBytesPerRow = 4 * origW
var origData = [UInt8](repeating: 0, count: origH * tempBytesPerRow)
guard let tempCtx = CGContext(
    data: &origData,
    width: origW,
    height: origH,
    bitsPerComponent: 8,
    bytesPerRow: tempBytesPerRow,
    space: tempColorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
) else {
    print("Error: tempCtx failed")
    exit(1)
}
tempCtx.draw(cgImage, in: CGRect(x: 0, y: 0, width: origW, height: origH))

var minX = origW, maxX = 0, minY = origH, maxY = 0
for y in 0..<origH {
    for x in 0..<origW {
        let offset = (y * origW + x) * 4
        let r = origData[offset]
        let g = origData[offset + 1]
        let b = origData[offset + 2]
        if r > 14 || g > 14 || b > 14 {
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
        }
    }
}

let cropW = maxX - minX + 1
let cropH = maxY - minY + 1
print("Cropping squircle bounding box: (\(minX), \(minY)) -> (\(maxX), \(maxY)) [Size: \(cropW) x \(cropH)]")

// Crop the CGImage tightly to the squircle
let cropRect = CGRect(x: minX, y: minY, width: cropW, height: cropH)
guard let croppedCG = cgImage.cropping(to: cropRect) else {
    print("Error: Cropping failed")
    exit(1)
}

// Render to a square 1024x1024 canvas filling 1000x1000 (12px edge safety)
let targetSize = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bytesPerRow = 4 * targetSize
var rawData = [UInt8](repeating: 0, count: targetSize * bytesPerRow)

guard let ctx = CGContext(
    data: &rawData,
    width: targetSize,
    height: targetSize,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
) else {
    print("Error: Target CGContext failed")
    exit(1)
}

let margin = 12
let squircleDrawRect = CGRect(x: margin, y: margin, width: targetSize - (2 * margin), height: targetSize - (2 * margin))
ctx.draw(croppedCG, in: squircleDrawRect)

// Flood fill from borders to remove any outer black corner pixels
var isBg = [Bool](repeating: false, count: targetSize * targetSize)
var queueX = [Int]()
var queueY = [Int]()

func isBlack(_ x: Int, _ y: Int) -> Bool {
    let offset = (y * targetSize + x) * 4
    let r = rawData[offset]
    let g = rawData[offset + 1]
    let b = rawData[offset + 2]
    return r < 18 && g < 18 && b < 18
}

for x in 0..<targetSize {
    if isBlack(x, 0) {
        isBg[x] = true
        queueX.append(x)
        queueY.append(0)
    }
    let bottomY = targetSize - 1
    if isBlack(x, bottomY) {
        isBg[bottomY * targetSize + x] = true
        queueX.append(x)
        queueY.append(bottomY)
    }
}
for y in 0..<targetSize {
    if isBlack(0, y) {
        isBg[y * targetSize] = true
        queueX.append(0)
        queueY.append(y)
    }
    let rightX = targetSize - 1
    if isBlack(rightX, y) {
        isBg[y * targetSize + rightX] = true
        queueX.append(rightX)
        queueY.append(y)
    }
}

var head = 0
while head < queueX.count {
    let cx = queueX[head]
    let cy = queueY[head]
    head += 1
    
    let nbrs = [(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)]
    for (nx, ny) in nbrs {
        if nx >= 0 && nx < targetSize && ny >= 0 && ny < targetSize {
            let idx = ny * targetSize + nx
            if !isBg[idx] && isBlack(nx, ny) {
                isBg[idx] = true
                queueX.append(nx)
                queueY.append(ny)
            }
        }
    }
}

// Anti-alias corners
var outData = rawData
for y in 0..<targetSize {
    for x in 0..<targetSize {
        let idx = y * targetSize + x
        let offset = idx * 4
        if isBg[idx] {
            outData[offset] = 0
            outData[offset + 1] = 0
            outData[offset + 2] = 0
            outData[offset + 3] = 0
        } else {
            var bgCount = 0
            for dy in -1...1 {
                for dx in -1...1 {
                    let nx = x + dx
                    let ny = y + dy
                    if nx >= 0 && nx < targetSize && ny >= 0 && ny < targetSize {
                        if isBg[ny * targetSize + nx] {
                            bgCount += 1
                        }
                    }
                }
            }
            if bgCount > 0 {
                let alphaFactor = max(0.0, 1.0 - (Double(bgCount) / 9.0) * 0.85)
                let currentA = Double(outData[offset + 3]) / 255.0
                outData[offset + 3] = UInt8(currentA * alphaFactor * 255.0)
            }
        }
    }
}

guard let outCtx = CGContext(
    data: &outData,
    width: targetSize,
    height: targetSize,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
), let resultCG = outCtx.makeImage() else {
    print("Error: Could not create final CGImage")
    exit(1)
}

let finalRep = NSBitmapImageRep(cgImage: resultCG)
guard let pngData = finalRep.representation(using: .png, properties: [:]) else {
    print("Error: PNG encoding failed")
    exit(1)
}

try pngData.write(to: URL(fileURLWithPath: outputTightPath))
try pngData.write(to: URL(fileURLWithPath: outputAppIconPng))
try pngData.write(to: URL(fileURLWithPath: "/Users/rinturajc/FrontEnd/ezkuCasting/icons/appicon_transparent.png"))

print("✅ Saved zero-padding transparent icon to:")
print("👉 \(outputTightPath)")
print("👉 \(outputAppIconPng)")
