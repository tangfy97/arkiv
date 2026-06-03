import Foundation
import UniformTypeIdentifiers

enum ViewMode {
    case ready
    case watching
    case archived
    case profiles
}

enum SessionRunState {
    case idle
    case running
    case paused
}

enum MonitorDuration: String, CaseIterable, Identifiable {
    case fifteen = "15 min"
    case thirty = "30 min"
    case hour = "1 hour"
    case infinite = "Until I stop"

    var id: String { rawValue }

    var fullLabel: String {
        switch self {
        case .fifteen: "15 minutes"
        case .thirty: "30 minutes"
        case .hour: "1 hour"
        case .infinite: "Until I stop"
        }
    }

    var seconds: TimeInterval? {
        switch self {
        case .fifteen: 15 * 60
        case .thirty: 30 * 60
        case .hour: 60 * 60
        case .infinite: nil
        }
    }
}

enum RecentWindow: String, CaseIterable, Identifiable {
    case thirty = "30 min"
    case hour = "1 hour"
    case today = "Today"

    var id: String { rawValue }

    func earliestDate(relativeTo date: Date) -> Date {
        switch self {
        case .thirty:
            date.addingTimeInterval(-30 * 60)
        case .hour:
            date.addingTimeInterval(-60 * 60)
        case .today:
            Calendar.current.startOfDay(for: date)
        }
    }
}

enum MediaKind: String, CaseIterable, Identifiable {
    case all = "All"
    case image = "Images"
    case video = "Videos"
    case other = "Other"
    case custom = "Custom"

    var id: String { rawValue }
}

enum FileSortMode: String, CaseIterable, Identifiable {
    case createdAt = "Created"
    case name = "Name"

    var id: String { rawValue }
}

enum ProfileEditorMode: String, CaseIterable, Identifiable {
    case edit = "Edit"
    case preview = "Preview"

    var id: String { rawValue }
}

struct ProfileSubject: Identifiable, Hashable {
    let name: String
    let url: URL
    let hasProfile: Bool

    var id: String { url.path }
}

enum FileReadiness: String {
    case downloading = "Downloading"
    case ready = "Ready"
    case missing = "Missing"

    var symbolName: String {
        switch self {
        case .downloading: "arrow.down.circle"
        case .ready: "checkmark.circle"
        case .missing: "exclamationmark.triangle"
        }
    }
}

struct DetectedFile: Identifiable, Hashable {
    let id: UUID
    var url: URL
    var displayName: String
    var fileExtension: String
    var kind: MediaKind
    var sizeBytes: Int64
    var lastObservedSizeBytes: Int64
    var stableTicks: Int
    var createdAt: Date
    var modifiedAt: Date
    var firstSeenAt: Date
    var readiness: FileReadiness
    var isSelected: Bool

    var isTemporaryDownload: Bool {
        Self.temporaryExtensions.contains(fileExtension.lowercased())
    }

    static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "tif", "tiff", "bmp", "avif"
    ]

    static let videoExtensions: Set<String> = [
        "mp4", "mov", "m4v", "webm", "avi", "mkv", "wmv", "flv", "mpeg", "mpg"
    ]

    static let temporaryExtensions: Set<String> = [
        "crdownload", "download", "part", "tmp"
    ]

    static func classify(_ url: URL) -> MediaKind {
        let ext = url.pathExtension.lowercased()

        if imageExtensions.contains(ext) {
            return .image
        }

        if videoExtensions.contains(ext) {
            return .video
        }

        if let type = UTType(filenameExtension: ext) {
            if type.conforms(to: .image) {
                return .image
            }

            if type.conforms(to: .movie) || type.conforms(to: .video) {
                return .video
            }
        }

        return .other
    }
}

struct ArchiveRecord: Codable, Identifiable {
    let id: UUID
    let originalPath: String
    let archivedPath: String
    let originalName: String
    let archivedName: String
    let sizeBytes: Int64
    let archivedAt: Date
}

struct ArchiveBatch: Codable, Identifiable {
    let id: UUID
    let targetName: String
    let setName: String
    let destinationFolder: String
    let createdAt: Date
    let records: [ArchiveRecord]

    var imageCount: Int {
        records.filter { URL(fileURLWithPath: $0.archivedPath).deletingLastPathComponent().lastPathComponent == "Images" }.count
    }

    var videoCount: Int {
        records.filter { URL(fileURLWithPath: $0.archivedPath).deletingLastPathComponent().lastPathComponent == "Videos" }.count
    }

    var otherCount: Int {
        records.count - imageCount - videoCount
    }
}

extension Int64 {
    var arkivByteString: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

extension String {
    var arkivSanitizedFileComponent: String {
        let illegal = CharacterSet(charactersIn: "/\\?%*:|\"<>")
        return components(separatedBy: illegal)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
