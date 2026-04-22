#if os(macOS)
import SwiftUI
import AppKit
import Combine

@main
struct PixelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Settings window is managed manually in AppDelegate for reliable behavior
    // with LSUIElement menu-bar apps. SwiftUI's Settings scene is fragile here.
    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class OverlayWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var statusItem: NSStatusItem?
    private var hitTestTimer: Timer?
    private var screenBounds: CGRect = .zero
    private var settingsWindow: NSWindow?
    let circleState = CircleState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        createOverlayWindow()
        createMenuBarItem()
        startHitTesting()
        installDiagnostics()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func installDiagnostics() {
        let nc = NotificationCenter.default
        let wsnc = NSWorkspace.shared.notificationCenter

        let logWindow: (String) -> Void = { [weak self] label in
            guard let w = self?.window else { return }
            NSLog("Pixel DIAG [%@] visible=%d onActiveSpace=%d frame=%@ level=%d",
                  label, w.isVisible ? 1 : 0, w.isOnActiveSpace ? 1 : 0,
                  NSStringFromRect(w.frame), w.level.rawValue)
        }

        wsnc.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { _ in
            logWindow("activeSpaceDidChange")
        }
        wsnc.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { note in
            let app = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.localizedName ?? "?"
            NSLog("Pixel DIAG [didActivateApplication:%@]", app)
            logWindow("didActivateApplication")
        }
        nc.addObserver(forName: NSWindow.didChangeOcclusionStateNotification, object: window, queue: .main) { [weak self] _ in
            let occluded = (self?.window?.occlusionState.contains(.visible) == false)
            NSLog("Pixel DIAG [occlusion] occluded=%d", occluded ? 1 : 0)
            logWindow("occlusion")
        }
        nc.addObserver(forName: NSWindow.didMoveNotification, object: window, queue: .main) { _ in
            logWindow("didMove")
        }
        nc.addObserver(forName: NSWindow.didResizeNotification, object: window, queue: .main) { _ in
            logWindow("didResize")
        }
        nc.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { _ in
            logWindow("didBecomeKey")
        }
        nc.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { _ in
            logWindow("didResignKey")
        }
        logWindow("afterOrderFront")
    }

    private func allScreensBounds() -> CGRect {
        NSScreen.screens.reduce(CGRect.null) { $0.union($1.frame) }
    }

    private func createOverlayWindow() {
        let bounds = allScreensBounds()
        guard !bounds.isNull else { return }
        screenBounds = bounds

        let window = OverlayWindow(
            contentRect: bounds,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.animationBehavior = .none
        window.level = .statusBar

        let root = ContentView(state: circleState)
        window.contentView = NSHostingView(rootView: root)

        if let main = NSScreen.main {
            let newPos = CGPoint(
                x: main.frame.midX - bounds.origin.x,
                y: bounds.origin.y + bounds.height - main.frame.midY
            )
            NSLog("Pixel DEBUG bounds=%@ main=%@ pos=%@", NSStringFromRect(bounds), NSStringFromRect(main.frame), NSStringFromPoint(newPos))
            circleState.position = newPos
        }

        self.window = window
        window.orderFrontRegardless()
    }

    @objc private func screensChanged() {
        guard let window = window else { return }
        let bounds = allScreensBounds()
        guard !bounds.isNull else { return }
        screenBounds = bounds
        window.setFrame(bounds, display: true)
    }

    private func createMenuBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Bloom")
        }
        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings…",
                                      action: #selector(openSettings),
                                      keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Bloom", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        self.statusItem = item
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsView(state: circleState))
            let window = NSWindow(contentViewController: hosting)
            window.title = "Bloom Settings"
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 340, height: 380))
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // Avatar menu was removed — no refresh needed now that only Settings + Quit remain.

    private var heartbeatCounter = 0
    private func startHitTesting() {
        hitTestTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.heartbeatCounter += 1
            if self.heartbeatCounter % 120 == 0 {
                let m = NSEvent.mouseLocation
                NSLog("Pixel HEARTBEAT t=%.1fs mouse=(%.0f,%.0f) ignoresMouse=%d isDragging=%d",
                      Double(self.heartbeatCounter) / 60.0, m.x, m.y,
                      self.window?.ignoresMouseEvents == true ? 1 : 0,
                      self.circleState.isDragging ? 1 : 0)
            }
            self.updateClickThrough()
        }
    }

    private func updateClickThrough() {
        guard let window = window else { return }

        if circleState.isDragging {
            if window.ignoresMouseEvents {
                window.ignoresMouseEvents = false
                NSLog("Pixel HIT drag→accept")
            }
            return
        }

        let mouse = NSEvent.mouseLocation
        let inView = CGPoint(
            x: mouse.x - screenBounds.origin.x,
            y: screenBounds.origin.y + screenBounds.height - mouse.y
        )

        let dx = inView.x - circleState.position.x
        let dy = inView.y - circleState.position.y
        let overCircle = (dx * dx + dy * dy) <= pow(circleState.radius + 4, 2)

        if window.ignoresMouseEvents == overCircle {
            window.ignoresMouseEvents = !overCircle
            NSLog("Pixel HIT toggle overCircle=%d ignoresMouse=%d mouse=(%.0f,%.0f) pos=(%.0f,%.0f)",
                  overCircle ? 1 : 0, !overCircle ? 1 : 0,
                  inView.x, inView.y, circleState.position.x, circleState.position.y)
        }
    }
}
#endif
