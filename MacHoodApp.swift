import SwiftUI

@main
struct MacHoodApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var daemon: DaemonConnection!

    private func installPythonDeps() {
        DispatchQueue.global(qos: .background).async {
            let pip = Process()
            pip.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            pip.arguments = ["pip3", "install", "pyobjc-framework-Quartz", "pynput"]
            pip.standardOutput = FileHandle.nullDevice
            pip.standardError  = FileHandle.nullDevice
            try? pip.run()
            pip.waitUntilExit()
        }
    }

    private func launchDaemon() {
        let resourcePath = Bundle.main.resourcePath!
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/python3")
        process.arguments = ["\(resourcePath)/machood_daemon.py"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError  = FileHandle.nullDevice
        try? process.run()
        Thread.sleep(forTimeInterval: 1.0)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installPythonDeps()
        NSApp.setActivationPolicy(.regular)
        daemon = DaemonConnection()
        launchDaemon()
        daemon.start()

        let contentView = ContentView()
            .environmentObject(daemon)

        window = RaycastWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 580),
            styleMask:   [.borderless, .fullSizeContentView],
            backing:     .buffered,
            defer:       false
        )
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            if e.keyCode == 53 {
                self?.window.orderOut(nil)
                return nil
            }
            if e.modifierFlags.contains(.command) && e.charactersIgnoringModifiers == "q" {
                NSApp.terminate(nil)
                return nil
            }
            return e
        }
    }
}
