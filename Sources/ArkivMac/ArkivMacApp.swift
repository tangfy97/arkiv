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
                .frame(width: 380, height: 524)
                .ignoresSafeArea()
                .preferredColorScheme(store.usesDarkAppearance ? .dark : .light)
                .background(WindowConfigurator())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
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
            window.setContentSize(NSSize(width: 380, height: 524))
            window.minSize = NSSize(width: 380, height: 524)
            window.maxSize = NSSize(width: 380, height: 524)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
