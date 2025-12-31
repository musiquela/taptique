#!/usr/bin/env swift

import AppKit

// Correct icon sizes for macOS App Store
let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

// Source image path
let sourcePath = "/Users/keegandewitt/Downloads/E8813/PNG/shape-100.png"

guard let sourceImage = NSImage(contentsOfFile: sourcePath) else {
    print("Error: Could not load source image from \(sourcePath)")
    exit(1)
}

func createIcon(from source: NSImage, pixelSize: Int) -> Data? {
    let size = NSSize(width: pixelSize, height: pixelSize)

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }

    bitmap.size = size

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    // Draw the source image scaled to fit
    let destRect = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    source.draw(in: destRect, from: .zero, operation: .copy, fraction: 1.0)

    NSGraphicsContext.restoreGraphicsState()

    return bitmap.representation(using: .png, properties: [:])
}

// Create icons directory path
let assetPath = "Taptique/Assets.xcassets/AppIcon.appiconset"

// Generate each size
for (pixelSize, filename) in sizes {
    if let pngData = createIcon(from: sourceImage, pixelSize: pixelSize) {
        let filepath = "\(assetPath)/\(filename)"
        try? pngData.write(to: URL(fileURLWithPath: filepath))
        print("Generated: \(filename) (\(pixelSize)x\(pixelSize) pixels)")
    } else {
        print("Failed to generate: \(filename)")
    }
}

print("\nApp icons generated from source image!")
