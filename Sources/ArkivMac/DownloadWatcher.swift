import CoreServices
import Foundation

final class DownloadWatcher: @unchecked Sendable {
    private let directoryURL: URL
    private let onChange: @MainActor @Sendable () -> Void
    private let queue = DispatchQueue(label: "app.arkiv.download-watcher", qos: .utility)
    private var stream: FSEventStreamRef?

    init(directoryURL: URL, onChange: @escaping @MainActor @Sendable () -> Void) {
        self.directoryURL = directoryURL
        self.onChange = onChange
    }

    func start() {
        guard stream == nil else { return }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<DownloadWatcher>.fromOpaque(info).takeUnretainedValue()
            Task { @MainActor in
                watcher.onChange()
            }
        }

        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagNoDefer
        )

        stream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            [directoryURL.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            flags
        )

        guard let stream else { return }
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    deinit {
        stop()
    }
}
