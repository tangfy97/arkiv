import AppKit
import SwiftUI

@main
struct ArkivMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .frame(width: AppWindowMetrics.width, height: AppWindowMetrics.height)
                .ignoresSafeArea()
                .preferredColorScheme(store.usesDarkAppearance ? .dark : .light)
                .background(WindowConfigurator())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

private enum AppWindowMetrics {
    static let width: CGFloat = 400
    static let height: CGFloat = 540
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.title = "Arkiv"
            window.level = .floating
            window.isMovableByWindowBackground = true
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.styleMask = [.borderless, .fullSizeContentView]
            window.titleVisibility = .hidden
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
            let size = NSSize(width: AppWindowMetrics.width, height: AppWindowMetrics.height)
            window.setContentSize(size)
            window.minSize = size
            window.maxSize = size
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
