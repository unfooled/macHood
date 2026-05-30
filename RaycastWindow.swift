import AppKit

class RaycastWindow: NSWindow {

    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {

        super.init(contentRect: contentRect,
                   styleMask: style,
                   backing: backingStoreType,
                   defer: flag)

        level              = .floating
        isOpaque           = false
        backgroundColor    = .clear
        hasShadow          = true
        titlebarAppearsTransparent = true
        titleVisibility    = .hidden
        isMovableByWindowBackground = true

        // Pure vibrancy — the dark tint comes from SwiftUI side
        let vibrancy = NSVisualEffectView()
        vibrancy.material     = .hudWindow
        vibrancy.blendingMode = .behindWindow
        vibrancy.state        = .active
        vibrancy.wantsLayer   = true
        vibrancy.layer?.cornerRadius  = 16
        vibrancy.layer?.masksToBounds = true
        contentView = vibrancy
    }

    override var canBecomeKey:  Bool { true }
    override var canBecomeMain: Bool { true }
}
