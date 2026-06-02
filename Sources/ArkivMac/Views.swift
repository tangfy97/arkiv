import SwiftUI

private enum ArkivStyle {
    static let ink = Color(red: 0.11, green: 0.12, blue: 0.12)
    static let secondary = Color(red: 0.42, green: 0.45, blue: 0.45)
    static let blue = Color(red: 0.33, green: 0.44, blue: 0.50)
    static let green = Color(red: 0.39, green: 0.55, blue: 0.43)
    static let amber = Color(red: 0.71, green: 0.53, blue: 0.29)
    static let glass = Color.white.opacity(0.24)
    static let glassStrong = Color.white.opacity(0.40)
    static let stroke = Color.white.opacity(0.46)
}

struct RootView: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        ZStack {
            LiquidSurface()

            VStack(spacing: 14) {
                AppHeader()

                Group {
                    switch store.viewMode {
                    case .ready:
                        SetupPanel()
                    case .watching:
                        MonitorPanel()
                    case .archived:
                        DonePanel()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.58), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 32, x: 0, y: 20)
        .animation(.smooth(duration: 0.22), value: store.viewMode)
        .animation(.smooth(duration: 0.18), value: store.runState)
    }
}

struct LiquidSurface: View {
    var body: some View {
        ZStack {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.34),
                    Color(red: 0.82, green: 0.88, blue: 0.88).opacity(0.15),
                    Color.white.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.plusLighter)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.08))
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct AppHeader: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .shadow(color: statusColor.opacity(0.5), radius: 5)

            Spacer()

            Text("ARKIV")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(4)
                .foregroundStyle(ArkivStyle.secondary)

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(ArkivStyle.secondary)
            .background(.white.opacity(0.18), in: Circle())
            .help("Quit Arkiv")
        }
        .frame(height: 30)
    }

    private var statusColor: Color {
        switch store.runState {
        case .idle:
            store.viewMode == .archived ? ArkivStyle.green : ArkivStyle.secondary.opacity(0.75)
        case .running:
            ArkivStyle.blue
        case .paused:
            ArkivStyle.amber
        }
    }
}

struct SetupPanel: View {
    @EnvironmentObject private var store: SessionStore
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 4)

            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(ArkivStyle.blue)
                .frame(width: 62, height: 62)
                .background(.white.opacity(0.20), in: Circle())

            TextField("Batch name", text: $store.targetName)
                .textFieldStyle(.plain)
                .focused($focused)
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(ArkivStyle.ink)
                .padding(.horizontal, 14)
                .frame(height: 54)
                .background(GlassCard(cornerRadius: 17, opacity: 0.28))

            VStack(spacing: 8) {
                FolderButton(title: "Watch", icon: "eye", path: store.watchFolderDisplayName) {
                    store.chooseWatchFolder()
                }

                FolderButton(title: "Save", icon: "archivebox", path: store.archiveRootDisplayName) {
                    store.chooseArchiveRoot()
                }
            }

            DurationPicker()

            RescueLine()

            Spacer(minLength: 4)

            Button {
                store.startSession()
            } label: {
                Label("Start", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(store.targetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .onAppear { focused = true }
    }
}

struct FolderButton: View {
    let title: String
    let icon: String
    let path: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 26, height: 26)
                    .background(.white.opacity(0.22), in: Circle())

                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ArkivStyle.ink)

                Text(path)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 2)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 11)
            .frame(height: 42)
            .background(GlassCard(cornerRadius: 15, opacity: 0.22))
        }
        .buttonStyle(.plain)
    }
}

struct DurationPicker: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        HStack(spacing: 6) {
            ForEach(MonitorDuration.allCases) { duration in
                Button {
                    store.monitorDuration = duration
                } label: {
                    Text(duration.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                }
                .buttonStyle(.plain)
                .foregroundStyle(store.monitorDuration == duration ? .white : ArkivStyle.secondary)
                .background(store.monitorDuration == duration ? ArkivStyle.ink.opacity(0.86) : .white.opacity(0.16), in: Capsule())
            }
        }
        .padding(4)
        .background(.white.opacity(0.14), in: Capsule())
    }
}

struct RescueLine: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        HStack(spacing: 9) {
            Toggle("", isOn: $store.includeRescueMode)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()

            Text("Include last")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ArkivStyle.secondary)

            Slider(value: $store.rescueMinutes, in: 5...45, step: 5)
                .tint(ArkivStyle.blue)

            Text("\(Int(store.rescueMinutes))m")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(ArkivStyle.secondary)
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(GlassCard(cornerRadius: 14, opacity: 0.18))
    }
}

struct MonitorPanel: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        VStack(spacing: 10) {
            MonitorTop()
            CountBar()
            ToolStrip()
            FileList()
            ArchiveBar()
        }
    }
}

struct MonitorTop: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(store.sanitizedTargetName)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .foregroundStyle(ArkivStyle.ink)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                store.togglePause()
            } label: {
                Image(systemName: store.runState == .paused ? "play.fill" : "pause.fill")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(IconButtonStyle())
            .help(store.runState == .paused ? "Resume" : "Pause")

            Button {
                store.cancelSession()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(IconButtonStyle())
            .help("Cancel")
        }
    }

    private var subtitle: String {
        if store.runState == .paused {
            return "Paused"
        }
        if let remaining = store.remainingSeconds {
            let minutes = max(0, Int(ceil(remaining / 60)))
            return "\(minutes)m left · \(store.watchFolderURL.lastPathComponent)"
        }
        return "Watching · \(store.watchFolderURL.lastPathComponent)"
    }
}

struct CountBar: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        HStack(spacing: 6) {
            CountPill(value: store.detectedCount, label: "Seen")
            CountPill(value: store.readyCount, label: "Ready")
            CountPill(value: store.selectedCount, label: "Pick")
        }
    }
}

struct CountPill: View {
    let value: Int
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background(GlassCard(cornerRadius: 13, opacity: 0.18))
    }
}

struct ToolStrip: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                FilterButton(kind: .all, symbol: "square.grid.2x2")
                FilterButton(kind: .image, symbol: "photo")
                FilterButton(kind: .video, symbol: "film")
                FilterButton(kind: .other, symbol: "doc")
                FilterButton(kind: .custom, symbol: "slider.horizontal.3")
            }

            HStack(spacing: 8) {
                Image(systemName: store.filter == .custom ? "number" : "magnifyingglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField(store.filter == .custom ? "jpg,png,mp4" : "Search filename", text: store.filter == .custom ? $store.customExtensions : $store.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: store.filter == .custom ? .monospaced : .default))
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(GlassCard(cornerRadius: 13, opacity: 0.18))
        }
    }
}

struct FilterButton: View {
    @EnvironmentObject private var store: SessionStore
    let kind: MediaKind
    let symbol: String

    var body: some View {
        Button {
            store.filter = kind
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 30)
        }
        .buttonStyle(.plain)
        .foregroundStyle(store.filter == kind ? .white : ArkivStyle.secondary)
        .background(store.filter == kind ? ArkivStyle.ink.opacity(0.86) : .white.opacity(0.14), in: Capsule())
        .help(kind.rawValue)
    }
}

struct FileList: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                if store.filteredFiles.isEmpty {
                    EmptyFilesState()
                } else {
                    ForEach(store.filteredFiles) { file in
                        FileRow(file: file)
                    }
                }
            }
            .padding(.vertical, 1)
        }
        .frame(height: 172)
        .scrollIndicators(.never)
    }
}

struct EmptyFilesState: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 22, weight: .light))
            Text(store.statusMessage)
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(GlassCard(cornerRadius: 16, opacity: 0.14))
    }
}

struct FileRow: View {
    @EnvironmentObject private var store: SessionStore
    let file: DetectedFile

    var body: some View {
        Button {
            store.toggleSelection(for: file)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 26, height: 26)
                    .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ArkivStyle.ink)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text("\(file.fileExtensionLabel) · \(file.sizeBytes.arkivByteString) · \(file.readiness.shortLabel)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(statusColor)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(file.isSelected ? ArkivStyle.blue : .secondary)
            }
            .padding(.horizontal, 9)
            .frame(height: 44)
            .background(GlassCard(cornerRadius: 14, opacity: file.isSelected ? 0.28 : 0.14))
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch file.kind {
        case .image: "photo"
        case .video: "film"
        case .other, .custom, .all: "doc"
        }
    }

    private var iconColor: Color {
        switch file.kind {
        case .image: ArkivStyle.green
        case .video: ArkivStyle.blue
        case .other, .custom, .all: ArkivStyle.secondary
        }
    }

    private var statusColor: Color {
        switch file.readiness {
        case .ready: .secondary
        case .downloading: ArkivStyle.amber
        case .missing: .red.opacity(0.65)
        }
    }
}

struct ArchiveBar: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        HStack(spacing: 8) {
            Button {
                store.selectAllFiltered()
            } label: {
                Text("All")
                    .frame(width: 44, height: 42)
            }
            .buttonStyle(GlassTextButtonStyle())

            Button {
                store.clearFilteredSelection()
            } label: {
                Text("None")
                    .frame(width: 52, height: 42)
            }
            .buttonStyle(GlassTextButtonStyle())

            Button {
                store.archiveSelected()
            } label: {
                Label(store.selectedReadyFiles.isEmpty ? "Archive" : "Archive \(store.selectedReadyFiles.count)", systemImage: "archivebox.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(store.selectedReadyFiles.isEmpty)
        }
    }
}

struct DonePanel: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(ArkivStyle.green)
                .frame(width: 70, height: 70)
                .background(GlassCard(cornerRadius: 35, opacity: 0.22))

            VStack(spacing: 7) {
                Text("Archived")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))

                if let batch = store.lastArchive {
                    Text("\(batch.records.count) files")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text(batch.destinationFolder)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(.white.opacity(0.16), in: Capsule())
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    store.undoLastArchive()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassWideButtonStyle())

                Button {
                    store.beginNewSession()
                } label: {
                    Label("New", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

struct GlassCard: View {
    let cornerRadius: CGFloat
    let opacity: Double

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.white.opacity(opacity))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(ArkivStyle.stroke, lineWidth: 0.8)
            }
            .shadow(color: .white.opacity(0.16), radius: 7, x: -2, y: -2)
            .shadow(color: .black.opacity(0.035), radius: 9, x: 0, y: 5)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(height: 46)
            .background(
                ArkivStyle.ink.opacity(isEnabled ? (configuration.isPressed ? 0.82 : 0.92) : 0.28),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ArkivStyle.secondary)
            .background(GlassCard(cornerRadius: 13, opacity: configuration.isPressed ? 0.34 : 0.18))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

struct GlassTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(ArkivStyle.secondary)
            .background(GlassCard(cornerRadius: 14, opacity: configuration.isPressed ? 0.32 : 0.18))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct GlassWideButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(ArkivStyle.ink)
            .frame(height: 46)
            .background(GlassCard(cornerRadius: 16, opacity: configuration.isPressed ? 0.34 : 0.20))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private extension DetectedFile {
    var fileExtensionLabel: String {
        fileExtension.isEmpty ? "file" : ".\(fileExtension)"
    }
}

private extension FileReadiness {
    var shortLabel: String {
        switch self {
        case .ready: "ready"
        case .downloading: "loading"
        case .missing: "missing"
        }
    }
}
