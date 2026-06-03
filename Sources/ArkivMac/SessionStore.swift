import Combine
import AppKit
import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published var usesDarkAppearance: Bool {
        didSet {
            UserDefaults.standard.set(usesDarkAppearance, forKey: Self.darkAppearanceDefaultsKey)
        }
    }
    @Published var viewMode: ViewMode = .ready
    @Published var runState: SessionRunState = .idle
    @Published var targetName = ""
    @Published var setName = ""
    @Published var detectedFiles: [DetectedFile] = []
    @Published var filter: MediaKind = .all
    @Published var sortMode: FileSortMode = .createdAt
    @Published var groupsByType = false
    @Published var searchText = ""
    @Published var customExtensions = "jpg,jpeg,png,gif,mp4,mov"
    @Published var includeRescueMode = true
    @Published var recentWindow: RecentWindow = .hour
    @Published var monitorDuration: MonitorDuration = .thirty
    @Published var remainingSeconds: TimeInterval?
    @Published var statusMessage = "Ready"
    @Published var lastArchive: ArchiveBatch?
    @Published var watchFolderURL: URL
    @Published var archiveRootURL: URL

    var watchFolderDisplayName: String { displayPath(watchFolderURL) }
    var archiveRootDisplayName: String { displayPath(archiveRootURL) }

    private var sessionStartedAt = Date()
    private var sessionEndsAt: Date?
    private var baselinePaths = Set<String>()
    private var watcher: DownloadWatcher?
    private var stabilityTimer: Timer?
    private var scanTask: Task<Void, Never>?
    private var scanGeneration = 0

    init(
        downloadsURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads"),
        archiveRootURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Pictures")
            .appendingPathComponent("Arkiv")
    ) {
        self.usesDarkAppearance = UserDefaults.standard.bool(forKey: Self.darkAppearanceDefaultsKey)
        self.watchFolderURL = downloadsURL
        self.archiveRootURL = archiveRootURL
    }

    var sanitizedTargetName: String {
        let sanitized = targetName.arkivSanitizedFileComponent
        return sanitized.isEmpty ? "Untitled" : sanitized
    }

    var suggestedSetNumber: Int {
        suggestedNextSetNumber(for: sanitizedTargetName)
    }

    var suggestedSetNumberText: String {
        Self.paddedSetNumber(suggestedSetNumber)
    }

    var effectiveSetName: String {
        Self.formattedSetName(effectiveSetNumber)
    }

    private var effectiveSetNumber: Int {
        guard let number = Int(Self.normalizedSetDigits(setName)), number > 0 else {
            return suggestedSetNumber
        }
        return number
    }

    func updateSetNumberInput(_ value: String) {
        setName = Self.normalizedSetDigits(value)
    }

    var filteredFiles: [DetectedFile] {
        detectedFiles
            .filter { file in
                matchesFilter(file) && matchesSearch(file)
            }
            .sorted { lhs, rhs in
                switch sortMode {
                case .createdAt:
                    if lhs.createdAt == rhs.createdAt {
                        return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
                    }
                    return lhs.createdAt > rhs.createdAt
                case .name:
                    return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
                }
            }
    }

    var selectedReadyFiles: [DetectedFile] {
        detectedFiles.filter { $0.isSelected && $0.readiness == .ready }
    }

    var filteredReadyFiles: [DetectedFile] {
        filteredFiles.filter { $0.readiness == .ready }
    }

    var allFilteredReadySelected: Bool {
        !filteredReadyFiles.isEmpty && filteredReadyFiles.allSatisfy(\.isSelected)
    }

    var detectedCount: Int { detectedFiles.count }
    var selectedCount: Int { selectedReadyFiles.count }
    var readyCount: Int { detectedFiles.filter { $0.readiness == .ready }.count }
    var downloadingCount: Int { detectedFiles.filter { $0.readiness == .downloading }.count }
    var selectedReadySize: Int64 { selectedReadyFiles.reduce(0) { $0 + $1.sizeBytes } }

    var groupedFilteredFiles: [(kind: MediaKind, files: [DetectedFile])] {
        guard groupsByType else {
            return [(.all, filteredFiles)]
        }

        return ([MediaKind.image, .video, .other]).compactMap { kind in
            let files = filteredFiles.filter { $0.kind == kind }
            return files.isEmpty ? nil : (kind, files)
        }
    }

    func setSortMode(_ mode: FileSortMode) {
        sortMode = mode
    }

    func toggleGroupByType() {
        groupsByType.toggle()
    }

    func toggleAppearance() {
        usesDarkAppearance.toggle()
    }

    func startSession() {
        guard !targetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        sessionStartedAt = Date()
        sessionEndsAt = monitorDuration.seconds.map { sessionStartedAt.addingTimeInterval($0) }
        remainingSeconds = monitorDuration.seconds
        baselinePaths = Self.currentRegularFilePaths(in: watchFolderURL)
        detectedFiles = []
        viewMode = .watching
        runState = .running
        statusMessage = "Watching \(watchFolderURL.lastPathComponent)"

        scanWatchedFolder()

        watcher = DownloadWatcher(directoryURL: watchFolderURL) { [weak self] in
            guard self?.runState == .running else { return }
            self?.scanWatchedFolder()
        }
        watcher?.start()

        stabilityTimer?.invalidate()
        stabilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickSession()
            }
        }
    }

    func stopSession() {
        watcher?.stop()
        watcher = nil
        stabilityTimer?.invalidate()
        stabilityTimer = nil
        scanTask?.cancel()
        scanTask = nil
        detectedFiles = []
        sessionEndsAt = nil
        remainingSeconds = nil
        runState = .idle
        statusMessage = "Ready"
        viewMode = .ready
    }

    func cancelSession() {
        stopSession()
    }

    func pauseSession() {
        guard viewMode == .watching, runState == .running else { return }
        runState = .paused
        statusMessage = "Paused"
    }

    func resumeSession() {
        guard viewMode == .watching, runState == .paused else { return }
        runState = .running
        statusMessage = "Watching \(watchFolderURL.lastPathComponent)"
        scanWatchedFolder()
    }

    func togglePause() {
        runState == .running ? pauseSession() : resumeSession()
    }

    func chooseWatchFolder() {
        guard let url = chooseFolder(title: "Choose a folder to watch", defaultURL: watchFolderURL) else { return }
        watchFolderURL = url
        statusMessage = "Watch folder set"
    }

    func chooseArchiveRoot() {
        guard let url = chooseFolder(title: "Choose archive destination", defaultURL: archiveRootURL) else { return }
        archiveRootURL = url
        statusMessage = "Archive destination set"
    }

    func toggleSelection(for file: DetectedFile) {
        guard let index = detectedFiles.firstIndex(where: { $0.id == file.id }) else { return }
        detectedFiles[index].isSelected.toggle()
    }

    func selectAllFiltered() {
        let ids = Set(filteredReadyFiles.map(\.id))
        for index in detectedFiles.indices where ids.contains(detectedFiles[index].id) {
            detectedFiles[index].isSelected = true
        }
    }

    func clearFilteredSelection() {
        let ids = Set(filteredReadyFiles.map(\.id))
        for index in detectedFiles.indices where ids.contains(detectedFiles[index].id) {
            detectedFiles[index].isSelected = false
        }
    }

    func toggleAllFilteredReady() {
        allFilteredReadySelected ? clearFilteredSelection() : selectAllFiltered()
    }

    func archiveSelected() {
        let files = selectedReadyFiles
        guard !files.isEmpty else {
            statusMessage = "No ready files selected"
            return
        }

        do {
            let batch = try createArchiveBatch(for: files)
            lastArchive = batch
            detectedFiles.removeAll { file in
                batch.records.contains { $0.originalPath == file.url.path }
            }
            statusMessage = "Archived \(batch.records.count) files"
            viewMode = .archived
            try writeLedger(batch)
        } catch {
            statusMessage = "Archive failed: \(error.localizedDescription)"
        }
    }

    func undoLastArchive() {
        guard let lastArchive else { return }

        do {
            for record in lastArchive.records.reversed() {
                let archivedURL = URL(fileURLWithPath: record.archivedPath)
                guard FileManager.default.fileExists(atPath: archivedURL.path) else { continue }

                let originalURL = uniqueURL(for: URL(fileURLWithPath: record.originalPath))
                try FileManager.default.createDirectory(
                    at: originalURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try FileManager.default.moveItem(at: archivedURL, to: originalURL)
            }

            self.lastArchive = nil
            viewMode = .watching
            runState = .running
            scanWatchedFolder()
            statusMessage = "Undo complete"
        } catch {
            statusMessage = "Undo failed: \(error.localizedDescription)"
        }
    }

    func beginNewSession() {
        lastArchive = nil
        stopSession()
        targetName = ""
        setName = ""
        searchText = ""
        filter = .all
    }

    func scanWatchedFolder() {
        guard runState == .running || viewMode == .ready else { return }
        scanGeneration += 1
        let generation = scanGeneration
        scanTask = Task { [watchFolderURL, includeRescueMode, recentWindow, sessionStartedAt, baselinePaths] in
            let scanned = await Self.scanDirectory(
                watchFolderURL,
                includeRescueMode: includeRescueMode,
                recentWindow: recentWindow,
                sessionStartedAt: sessionStartedAt,
                baselinePaths: baselinePaths
            )

            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard generation == self.scanGeneration else { return }
                switch scanned {
                case .success(let files):
                    self.mergeScannedFiles(files)
                    if self.runState == .running {
                        self.statusMessage = files.isEmpty ? "Watching. No files yet." : "Watching \(files.count) files"
                    }
                case .failure(let error):
                    self.statusMessage = error.localizedDescription
                }
            }
        }
    }

    private static func scanDirectory(
        _ url: URL,
        includeRescueMode: Bool,
        recentWindow: RecentWindow,
        sessionStartedAt: Date,
        baselinePaths: Set<String>
    ) async -> Result<[DetectedFile], ScanError> {
        let fileManager = FileManager.default
        let keys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .isHiddenKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey
        ]

        let urls: [URL]
        do {
            urls = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsPackageDescendants, .skipsHiddenFiles]
            )
        } catch {
            return .failure(.cannotReadFolder(url, error))
        }

        let earliest = includeRescueMode ? recentWindow.earliestDate(relativeTo: sessionStartedAt) : sessionStartedAt

        let files: [DetectedFile] = urls.compactMap { fileURL in
            guard let values = try? fileURL.resourceValues(forKeys: keys),
                  values.isRegularFile == true,
                  values.isHidden != true
            else {
                return nil
            }

            let createdAt = values.creationDate ?? Date.distantPast
            let modifiedAt = values.contentModificationDate ?? createdAt
            let isNewSinceSession = !baselinePaths.contains(fileURL.path)
            let isRescuedRecentFile = includeRescueMode && max(createdAt, modifiedAt) >= earliest
            guard isNewSinceSession || isRescuedRecentFile else { return nil }

            let size = Int64(values.fileSize ?? 0)
            let ext = fileURL.pathExtension.lowercased()
            let readiness: FileReadiness = DetectedFile.temporaryExtensions.contains(ext) ? .downloading : .downloading

            return DetectedFile(
                id: UUID(),
                url: fileURL,
                displayName: fileURL.lastPathComponent,
                fileExtension: ext,
                kind: DetectedFile.classify(fileURL),
                sizeBytes: size,
                lastObservedSizeBytes: size,
                stableTicks: 0,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                firstSeenAt: Date(),
                readiness: readiness,
                isSelected: true
            )
        }

        return .success(files)
    }

    private func mergeScannedFiles(_ scanned: [DetectedFile]) {
        let existingByPath = Dictionary(uniqueKeysWithValues: detectedFiles.map { ($0.url.path, $0) })
        let scannedPaths = Set(scanned.map { $0.url.path })

        var merged: [DetectedFile] = scanned.map { scannedFile in
            guard var existing = existingByPath[scannedFile.url.path] else {
                return scannedFile
            }

            existing.displayName = scannedFile.displayName
            existing.fileExtension = scannedFile.fileExtension
            existing.kind = scannedFile.kind
            existing.createdAt = scannedFile.createdAt
            existing.modifiedAt = scannedFile.modifiedAt

            if existing.sizeBytes == scannedFile.sizeBytes {
                existing.stableTicks += 1
            } else {
                existing.stableTicks = 0
                existing.lastObservedSizeBytes = existing.sizeBytes
            }

            existing.sizeBytes = scannedFile.sizeBytes
            if existing.isTemporaryDownload {
                existing.readiness = .downloading
            } else if existing.stableTicks >= 2 {
                existing.readiness = .ready
            } else {
                existing.readiness = .downloading
            }

            return existing
        }

        for missing in detectedFiles where !scannedPaths.contains(missing.url.path) {
            var missingFile = missing
            missingFile.readiness = .missing
            merged.append(missingFile)
        }

        detectedFiles = merged.sorted {
            if readinessRank($0.readiness) != readinessRank($1.readiness) {
                return readinessRank($0.readiness) > readinessRank($1.readiness)
            }
            return $0.firstSeenAt > $1.firstSeenAt
        }
    }

    private func refreshReadiness() {
        for index in detectedFiles.indices {
            guard FileManager.default.fileExists(atPath: detectedFiles[index].url.path) else {
                detectedFiles[index].readiness = .missing
                continue
            }

            if detectedFiles[index].isTemporaryDownload {
                detectedFiles[index].readiness = .downloading
            } else if detectedFiles[index].stableTicks >= 2 {
                detectedFiles[index].readiness = .ready
            }
        }
    }

    private func matchesFilter(_ file: DetectedFile) -> Bool {
        switch filter {
        case .all:
            true
        case .image:
            file.kind == .image
        case .video:
            file.kind == .video
        case .other:
            file.kind == .other
        case .custom:
            customExtensionSet.contains(file.fileExtension.lowercased())
        }
    }

    private func matchesSearch(_ file: DetectedFile) -> Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return file.displayName.localizedCaseInsensitiveContains(trimmed)
    }

    private var customExtensionSet: Set<String> {
        Set(
            customExtensions
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .map { $0.hasPrefix(".") ? String($0.dropFirst()) : $0 }
                .filter { !$0.isEmpty }
        )
    }

    private func createArchiveBatch(for files: [DetectedFile]) throws -> ArchiveBatch {
        let subjectFolder = archiveRootURL
            .appendingPathComponent(sanitizedTargetName)
        try FileManager.default.createDirectory(at: subjectFolder, withIntermediateDirectories: true)
        try migrateFlatTypeFoldersIfNeeded(in: subjectFolder)

        let destinationFolder = subjectFolder
            .appendingPathComponent(effectiveSetName)
        try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

        let plannedMoves: [(DetectedFile, URL)] = files.enumerated().map { index, file in
            let typedFolder = destinationFolder.appendingPathComponent(file.archiveSubfolderName)
            try? FileManager.default.createDirectory(at: typedFolder, withIntermediateDirectories: true)
            let baseName = "\(sanitizedTargetName)_\(effectiveSetName)_\(Self.fileNameDateFormatter.string(from: Date()))_\(String(format: "%03d", index + 1))"
            let proposedURL = typedFolder
                .appendingPathComponent(baseName)
                .appendingPathExtension(file.fileExtension.isEmpty ? file.url.pathExtension : file.fileExtension)
            return (file, uniqueURL(for: proposedURL))
        }

        var moved: [(from: URL, to: URL)] = []
        var records: [ArchiveRecord] = []

        do {
            for (file, destinationURL) in plannedMoves {
                try FileManager.default.moveItem(at: file.url, to: destinationURL)
                moved.append((file.url, destinationURL))
                records.append(
                    ArchiveRecord(
                        id: file.id,
                        originalPath: file.url.path,
                        archivedPath: destinationURL.path,
                        originalName: file.displayName,
                        archivedName: destinationURL.lastPathComponent,
                        sizeBytes: file.sizeBytes,
                        archivedAt: Date()
                    )
                )
            }
        } catch {
            for move in moved.reversed() {
                try? FileManager.default.moveItem(at: move.to, to: uniqueURL(for: move.from))
            }
            throw error
        }

        return ArchiveBatch(
            id: UUID(),
            targetName: sanitizedTargetName,
            setName: effectiveSetName,
            destinationFolder: destinationFolder.path,
            createdAt: Date(),
            records: records
        )
    }

    private func writeLedger(_ batch: ArchiveBatch) throws {
        let ledgerFolder = archiveRootURL.appendingPathComponent(".arkiv-ledger")
        try FileManager.default.createDirectory(at: ledgerFolder, withIntermediateDirectories: true)
        let ledgerURL = ledgerFolder.appendingPathComponent("\(batch.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(batch).write(to: ledgerURL, options: .atomic)
    }

    private func uniqueURL(for proposedURL: URL) -> URL {
        var candidate = proposedURL
        let fileManager = FileManager.default
        let base = proposedURL.deletingPathExtension()
        let ext = proposedURL.pathExtension
        var counter = 2

        while fileManager.fileExists(atPath: candidate.path) {
            let nextBase = URL(fileURLWithPath: "\(base.path)-\(counter)")
            candidate = ext.isEmpty ? nextBase : nextBase.appendingPathExtension(ext)
            counter += 1
        }

        return candidate
    }

    private func suggestedNextSetNumber(for subjectName: String) -> Int {
        let subjectFolder = archiveRootURL.appendingPathComponent(subjectName)
        var highestSetNumber = subjectHasFlatTypeFolders(subjectFolder) ? 1 : 0

        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: subjectFolder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 1
        }

        for url in urls {
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { continue }
            guard let number = Self.setNumber(from: url.lastPathComponent) else { continue }
            highestSetNumber = max(highestSetNumber, number)
        }

        return highestSetNumber + 1
    }

    private func subjectHasFlatTypeFolders(_ subjectFolder: URL) -> Bool {
        Self.archiveTypeFolderNames.contains { folderName in
            let url = subjectFolder.appendingPathComponent(folderName)
            return (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
    }

    private func migrateFlatTypeFoldersIfNeeded(in subjectFolder: URL) throws {
        let set001Folder = subjectFolder.appendingPathComponent(Self.formattedSetName(1))
        var migratedAnyFolder = false

        for folderName in Self.archiveTypeFolderNames {
            let flatFolder = subjectFolder.appendingPathComponent(folderName)
            guard (try? flatFolder.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { continue }

            let targetFolder = set001Folder.appendingPathComponent(folderName)
            try FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true)

            let contents = try FileManager.default.contentsOfDirectory(
                at: flatFolder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            for item in contents {
                try FileManager.default.moveItem(
                    at: item,
                    to: uniqueURL(for: targetFolder.appendingPathComponent(item.lastPathComponent))
                )
            }

            try? FileManager.default.removeItem(at: flatFolder)
            migratedAnyFolder = true
        }

        if migratedAnyFolder {
            statusMessage = "Moved existing files into Set 001"
        }
    }

    private func tickSession() {
        guard runState == .running else { return }

        if let sessionEndsAt {
            remainingSeconds = max(0, sessionEndsAt.timeIntervalSinceNow)
            if sessionEndsAt <= Date() {
                pauseSession()
                statusMessage = "Monitor time ended"
                return
            }
        }

        scanWatchedFolder()
        refreshReadiness()
    }

    private func chooseFolder(title: String, defaultURL: URL) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.directoryURL = defaultURL
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func displayPath(_ url: URL) -> String {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        let path = url.path
        if path == homePath {
            return "~"
        }
        if path.hasPrefix(homePath + "/") {
            return "~" + path.dropFirst(homePath.count)
        }
        return path
    }

    private func readinessRank(_ readiness: FileReadiness) -> Int {
        switch readiness {
        case .ready: 3
        case .downloading: 2
        case .missing: 1
        }
    }

    private static func currentRegularFilePaths(in url: URL) -> Set<String> {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isHiddenKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsPackageDescendants, .skipsHiddenFiles]
        ) else {
            return []
        }

        return Set(urls.compactMap { fileURL in
            guard let values = try? fileURL.resourceValues(forKeys: keys),
                  values.isRegularFile == true,
                  values.isHidden != true
            else {
                return nil
            }
            return fileURL.path
        })
    }

    private static let fileNameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let archiveTypeFolderNames = ["Images", "Videos", "Other"]
    private static let maxSetDigits = 3

    private static func formattedSetName(_ number: Int) -> String {
        "Set \(paddedSetNumber(number))"
    }

    private static func paddedSetNumber(_ number: Int) -> String {
        String(format: "%03d", max(1, number))
    }

    private static func normalizedSetDigits(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(maxSetDigits))
    }

    private static func setNumber(from folderName: String) -> Int? {
        let pattern = /^Set\s+(\d+)$/
        guard let match = folderName.wholeMatch(of: pattern),
              let number = Int(match.1)
        else {
            return nil
        }
        return number
    }

    private static let darkAppearanceDefaultsKey = "ArkivUsesDarkAppearance"
}

enum ScanError: LocalizedError {
    case cannotReadFolder(URL, Error)

    var errorDescription: String? {
        switch self {
        case .cannotReadFolder(let url, _):
            "Cannot read \(url.lastPathComponent). Choose the folder again."
        }
    }
}

private extension DetectedFile {
    var archiveSubfolderName: String {
        switch kind {
        case .image:
            "Images"
        case .video:
            "Videos"
        case .all, .custom, .other:
            "Other"
        }
    }
}
