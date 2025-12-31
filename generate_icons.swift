#!/usr/bin/env swift

import AppKit

// Icon sizes needed for macOS App Store
let sizes: [(size: Int, scale: Int, name: String)] = [
    (16, 1, "icon_16x16"),
    (16, 2, "icon_16x16@2x"),
    (32, 1, "icon_32x32"),
    (32, 2, "icon_32x32@2x"),
    (128, 1, "icon_128x128"),
    (128, 2, "icon_128x128@2x"),
    (256, 1, "icon_256x256"),
    (256, 2, "icon_256x256@2x"),
    (512, 1, "icon_512x512"),
    (512, 2, "icon_512x512@2x"),
]

func createMetronomeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)

    // Background - rounded rectangle with gradient
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.02, dy: size * 0.02),
                               xRadius: size * 0.18, yRadius: size * 0.18)

    // Gradient background
    let gradient = NSGradient(colors: [
        NSColor(red: 0.98, green: 0.45, blue: 0.25, alpha: 1.0),  // Orange-red top
        NSColor(red: 0.85, green: 0.25, blue: 0.20, alpha: 1.0)   // Deeper red bottom
    ])!
    gradient.draw(in: bgPath, angle: -90)

    // Subtle inner shadow/border
    let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.03, dy: size * 0.03),
                                   xRadius: size * 0.16, yRadius: size * 0.16)
    NSColor(white: 1.0, alpha: 0.1).setStroke()
    borderPath.lineWidth = size * 0.01
    borderPath.stroke()

    // Metronome body dimensions
    let bodyInset = size * 0.15
    let bodyRect = rect.insetBy(dx: bodyInset, dy: bodyInset)

    // Metronome body (trapezoid shape)
    let bodyPath = NSBezierPath()
    let baseWidth = bodyRect.width * 0.75
    let topWidth = bodyRect.width * 0.35
    let baseX = bodyRect.minX + (bodyRect.width - baseWidth) / 2
    let topX = bodyRect.minX + (bodyRect.width - topWidth) / 2
    let baseY = bodyRect.minY + bodyRect.height * 0.08
    let topY = bodyRect.maxY - bodyRect.height * 0.05

    bodyPath.move(to: NSPoint(x: baseX, y: baseY))
    bodyPath.line(to: NSPoint(x: baseX + baseWidth, y: baseY))
    bodyPath.line(to: NSPoint(x: topX + topWidth, y: topY))
    bodyPath.line(to: NSPoint(x: topX, y: topY))
    bodyPath.close()

    // Body gradient (wood-like)
    let bodyGradient = NSGradient(colors: [
        NSColor(red: 0.28, green: 0.20, blue: 0.15, alpha: 1.0),
        NSColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1.0),
        NSColor(red: 0.28, green: 0.20, blue: 0.15, alpha: 1.0)
    ])!
    bodyGradient.draw(in: bodyPath, angle: 0)

    // Body outline
    NSColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 1.0).setStroke()
    bodyPath.lineWidth = size * 0.015
    bodyPath.stroke()

    // Face plate (lighter area)
    let faceInset = size * 0.06
    let facePath = NSBezierPath()
    let faceBaseWidth = baseWidth - faceInset * 2
    let faceTopWidth = topWidth - faceInset * 0.5
    let faceBaseX = baseX + faceInset
    let faceTopX = topX + faceInset * 0.25
    let faceBaseY = baseY + faceInset
    let faceTopY = topY - faceInset

    facePath.move(to: NSPoint(x: faceBaseX, y: faceBaseY))
    facePath.line(to: NSPoint(x: faceBaseX + faceBaseWidth, y: faceBaseY))
    facePath.line(to: NSPoint(x: faceTopX + faceTopWidth, y: faceTopY))
    facePath.line(to: NSPoint(x: faceTopX, y: faceTopY))
    facePath.close()

    NSColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0).setFill()
    facePath.fill()

    // Pendulum pivot point
    let pivotY = faceTopY - size * 0.06
    let pivotX = bodyRect.midX

    // Pendulum arm (angled)
    let pendulumPath = NSBezierPath()
    let pendulumLength = size * 0.35
    let pendulumAngle: CGFloat = 0.35  // radians, tilted right
    let pendulumEndX = pivotX + sin(pendulumAngle) * pendulumLength
    let pendulumEndY = pivotY - cos(pendulumAngle) * pendulumLength

    pendulumPath.move(to: NSPoint(x: pivotX, y: pivotY))
    pendulumPath.line(to: NSPoint(x: pendulumEndX, y: pendulumEndY))

    NSColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0).setStroke()
    pendulumPath.lineWidth = size * 0.025
    pendulumPath.lineCapStyle = .round
    pendulumPath.stroke()

    // Pendulum weight
    let weightRadius = size * 0.055
    let weightY = pivotY - cos(pendulumAngle) * pendulumLength * 0.6
    let weightX = pivotX + sin(pendulumAngle) * pendulumLength * 0.6
    let weightPath = NSBezierPath(ovalIn: NSRect(
        x: weightX - weightRadius,
        y: weightY - weightRadius,
        width: weightRadius * 2,
        height: weightRadius * 2
    ))

    NSColor(red: 0.7, green: 0.55, blue: 0.0, alpha: 1.0).setFill()
    weightPath.fill()
    NSColor(red: 0.5, green: 0.4, blue: 0.0, alpha: 1.0).setStroke()
    weightPath.lineWidth = size * 0.01
    weightPath.stroke()

    // Tempo markings (small lines on face)
    let markingColor = NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.6)
    markingColor.setStroke()

    for i in stride(from: -3, through: 3, by: 1) {
        if i == 0 { continue }
        let markPath = NSBezierPath()
        let angle = CGFloat(i) * 0.15
        let startDist = size * 0.18
        let endDist = size * 0.22

        markPath.move(to: NSPoint(
            x: pivotX + sin(angle) * startDist,
            y: pivotY - cos(angle) * startDist
        ))
        markPath.line(to: NSPoint(
            x: pivotX + sin(angle) * endDist,
            y: pivotY - cos(angle) * endDist
        ))
        markPath.lineWidth = size * 0.008
        markPath.stroke()
    }

    // Pivot cap
    let pivotRadius = size * 0.025
    let pivotPath = NSBezierPath(ovalIn: NSRect(
        x: pivotX - pivotRadius,
        y: pivotY - pivotRadius,
        width: pivotRadius * 2,
        height: pivotRadius * 2
    ))
    NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0).setFill()
    pivotPath.fill()

    image.unlockFocus()
    return image
}

// Create icons directory path
let assetPath = "TapTempo/Assets.xcassets/AppIcon.appiconset"

// Generate each size
for config in sizes {
    let pixelSize = config.size * config.scale
    let icon = createMetronomeIcon(size: CGFloat(pixelSize))

    if let tiffData = icon.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let filename = "\(assetPath)/\(config.name).png"
        try? pngData.write(to: URL(fileURLWithPath: filename))
        print("Generated: \(config.name).png (\(pixelSize)x\(pixelSize))")
    }
}

print("\nApp icons generated successfully!")
