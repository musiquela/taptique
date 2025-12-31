import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var tapTempoEngine = TapTempoEngine()
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateButtonDisplay(button: button, bpm: nil)
            button.action = #selector(handleTap)
            button.target = self
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }
    }

    private func updateButtonDisplay(button: NSStatusBarButton, bpm: Int?) {
        if let bpm = bpm {
            // Show BPM with small metronome icon
            let font = NSFont.menuBarFont(ofSize: 0)
            let imageSize: CGFloat = 16

            let imageAttachment = NSTextAttachment()
            imageAttachment.image = createMetronomeImage(size: NSSize(width: imageSize, height: imageSize))

            // Adjust vertical position to center with text
            let yOffset = (font.capHeight - imageSize) / 2.0
            imageAttachment.bounds = CGRect(x: 0, y: yOffset, width: imageSize, height: imageSize)

            let attributedString = NSMutableAttributedString()
            attributedString.append(NSAttributedString(attachment: imageAttachment))
            attributedString.append(NSAttributedString(string: " \(bpm)", attributes: [.font: font]))

            button.attributedTitle = attributedString
            button.image = nil
        } else {
            // Show just the metronome icon
            button.title = ""
            button.image = createMetronomeImage(size: NSSize(width: 18, height: 18))
        }
    }

    private func createMetronomeImage(size: NSSize) -> NSImage {
        let image = NSImage(size: size, flipped: false) { rect in
            // Draw metronome shape
            let path = NSBezierPath()

            // Base
            let baseY = rect.height * 0.1
            let baseWidth = rect.width * 0.7
            let baseX = (rect.width - baseWidth) / 2
            path.move(to: NSPoint(x: baseX, y: baseY))
            path.line(to: NSPoint(x: baseX + baseWidth, y: baseY))

            // Triangle body
            let topX = rect.width / 2
            let topY = rect.height * 0.9
            path.line(to: NSPoint(x: topX + rect.width * 0.15, y: topY))
            path.line(to: NSPoint(x: topX - rect.width * 0.15, y: topY))
            path.close()

            NSColor.labelColor.setFill()
            path.fill()

            // Pendulum line
            let pendulumPath = NSBezierPath()
            let pendulumStartY = rect.height * 0.2
            let pendulumEndY = rect.height * 0.75
            pendulumPath.move(to: NSPoint(x: topX, y: pendulumStartY))
            pendulumPath.line(to: NSPoint(x: topX + rect.width * 0.12, y: pendulumEndY))
            pendulumPath.lineWidth = 1.5
            NSColor.windowBackgroundColor.setStroke()
            pendulumPath.stroke()

            // Pendulum weight
            let weightRadius = rect.width * 0.08
            let weightCenter = NSPoint(x: topX + rect.width * 0.12, y: pendulumEndY)
            let weightPath = NSBezierPath(ovalIn: NSRect(
                x: weightCenter.x - weightRadius,
                y: weightCenter.y - weightRadius,
                width: weightRadius * 2,
                height: weightRadius * 2
            ))
            NSColor.windowBackgroundColor.setFill()
            weightPath.fill()

            return true
        }

        image.isTemplate = true
        return image
    }

    @objc private func handleTap(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent

        if event?.type == .rightMouseDown {
            showContextMenu()
        } else {
            // Left click - tap tempo
            tapTempoEngine.tap()

            if let bpm = tapTempoEngine.currentBPM {
                updateButtonDisplay(button: sender, bpm: bpm)
            }
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        if let bpm = tapTempoEngine.currentBPM {
            let bpmItem = NSMenuItem(title: "Current: \(bpm) BPM", action: nil, keyEquivalent: "")
            bpmItem.isEnabled = false
            menu.addItem(bpmItem)
            menu.addItem(NSMenuItem.separator())
        }

        menu.addItem(NSMenuItem(title: "Reset", action: #selector(resetTempo), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Tap Tempo", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil // Remove menu so clicks work again
    }

    @objc private func resetTempo() {
        tapTempoEngine.reset()
        if let button = statusItem.button {
            updateButtonDisplay(button: button, bpm: nil)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
