import AppKit

let width: CGFloat = 660
let height: CGFloat = 420
let scale: CGFloat = 2.0

let pixelWidth = Int(width * scale)
let pixelHeight = Int(height * scale)

guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
    fputs("Error: Failed to create sRGB color space\n", stderr)
    exit(1)
}

guard let context = CGContext(
    data: nil,
    width: pixelWidth,
    height: pixelHeight,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Error: Failed to create CGContext\n", stderr)
    exit(1)
}

context.scaleBy(x: scale, y: scale)

// 1. Sleek dark gradient background
let bgColors = [
    NSColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0).cgColor,
    NSColor(red: 0.13, green: 0.15, blue: 0.19, alpha: 1.0).cgColor
] as CFArray
if let bgGrad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
    context.drawLinearGradient(bgGrad, start: CGPoint(x: 0, y: height), end: CGPoint(x: width, y: 0), options: [])
}

// 2. Subtle radial glows behind App icon (x: 175, y: 210) and Applications (x: 485, y: 210)
// CGContext y=0 is bottom, Finder y=0 is top. Finder y=210 corresponds to CGContext y=210.
func drawGlow(center: CGPoint, radius: CGFloat, color: NSColor) {
    let glowColors = [
        color.withAlphaComponent(0.22).cgColor,
        color.withAlphaComponent(0.0).cgColor
    ] as CFArray
    if let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        context.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
    }
}

drawGlow(center: CGPoint(x: 175, y: 210), radius: 140, color: NSColor(red: 0.2, green: 0.55, blue: 1.0, alpha: 1.0))
drawGlow(center: CGPoint(x: 485, y: 210), radius: 140, color: NSColor(red: 0.55, green: 0.35, blue: 0.95, alpha: 1.0))

// 3. Drop Zone target rings (subtle guides around where icons land)
func drawTargetRing(center: CGPoint, radius: CGFloat) {
    context.saveGState()
    let ringPath = CGPath(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2), transform: nil)
    context.addPath(ringPath)
    context.setStrokeColor(NSColor.white.withAlphaComponent(0.06).cgColor)
    context.setLineWidth(1)
    let dashes: [CGFloat] = [4, 4]
    context.setLineDash(phase: 0, lengths: dashes)
    context.strokePath()
    context.restoreGState()
}
drawTargetRing(center: CGPoint(x: 175, y: 210), radius: 68)
drawTargetRing(center: CGPoint(x: 485, y: 210), radius: 68)

// 4. Decorative Arrow between x: 260 and x: 400 (y: 210)
let arrowY: CGFloat = 210
context.saveGState()

context.setShadow(offset: .zero, blur: 16, color: NSColor(red: 0.35, green: 0.65, blue: 1.0, alpha: 0.7).cgColor)

let arrowPath = CGMutablePath()
let startX: CGFloat = 265
let endX: CGFloat = 370
let shaftH: CGFloat = 5
let headW: CGFloat = 18
let headH: CGFloat = 15

arrowPath.addRoundedRect(in: CGRect(x: startX, y: arrowY - shaftH/2, width: endX - startX, height: shaftH), cornerWidth: shaftH/2, cornerHeight: shaftH/2)

// Arrowhead
arrowPath.move(to: CGPoint(x: endX - 4, y: arrowY + headH))
arrowPath.addLine(to: CGPoint(x: endX + headW, y: arrowY))
arrowPath.addLine(to: CGPoint(x: endX - 4, y: arrowY - headH))
arrowPath.addLine(to: CGPoint(x: endX, y: arrowY))
arrowPath.closeSubpath()

let arrowColors = [
    NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.95).cgColor,
    NSColor(red: 0.8, green: 0.45, blue: 1.0, alpha: 1.0).cgColor
] as CFArray
if let arrowGrad = CGGradient(colorsSpace: colorSpace, colors: arrowColors, locations: [0.0, 1.0]) {
    context.addPath(arrowPath)
    context.clip()
    context.drawLinearGradient(arrowGrad, start: CGPoint(x: startX, y: arrowY), end: CGPoint(x: endX + headW, y: arrowY), options: [])
}
context.restoreGState()

// Decorative Chevrons along arrow
context.saveGState()
context.setStrokeColor(NSColor.white.withAlphaComponent(0.85).cgColor)
for cx in [startX + 34, startX + 56, startX + 78] {
    let cp = CGMutablePath()
    cp.move(to: CGPoint(x: cx - 4, y: arrowY + 6))
    cp.addLine(to: CGPoint(x: cx + 2, y: arrowY))
    cp.addLine(to: CGPoint(x: cx - 4, y: arrowY - 6))
    context.addPath(cp)
    context.setLineWidth(2.2)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.strokePath()
}
context.restoreGState()

// 5. Subtle Outer Border
let borderPath = CGPath(roundedRect: CGRect(x: 1, y: 1, width: width - 2, height: height - 2), cornerWidth: 16, cornerHeight: 16, transform: nil)
context.addPath(borderPath)
context.setStrokeColor(NSColor.white.withAlphaComponent(0.1).cgColor)
context.setLineWidth(1)
context.strokePath()

// 6. Text Elements
let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
NSGraphicsContext.current = graphicsContext

func drawCenteredText(_ text: String, y: CGFloat, font: NSFont, color: NSColor) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let strSize = attrStr.size()
    let x = (width - strSize.width) / 2
    attrStr.draw(at: NSPoint(x: x, y: y))
}

// Title and Subtitle at the top
let titleFont = NSFont.systemFont(ofSize: 22, weight: .bold)
drawCenteredText("ezku.link", y: 358, font: titleFont, color: NSColor.white)

let subFont = NSFont.systemFont(ofSize: 13, weight: .medium)
drawCenteredText("Drag ezku.link to Applications to install", y: 334, font: subFont, color: NSColor(white: 0.7, alpha: 1.0))

// Footer at the bottom
let footerFont = NSFont.systemFont(ofSize: 11, weight: .regular)
drawCenteredText("Ultra-low Latency Screen Mirroring & 4K Video Streaming", y: 32, font: footerFont, color: NSColor(white: 0.45, alpha: 1.0))

guard let cgImage = context.makeImage() else {
    fputs("Error: makeImage failed\n", stderr)
    exit(1)
}

let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
bitmapRep.size = NSSize(width: width, height: height)
guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    fputs("Error: PNG representation failed\n", stderr)
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/dmg_background.png"
let outUrl = URL(fileURLWithPath: outputPath)
try pngData.write(to: outUrl)
print("✅ Background rendered successfully: \(outUrl.path)")
