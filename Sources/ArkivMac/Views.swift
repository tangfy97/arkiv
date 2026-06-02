import SwiftUI

private enum ArkivStyle {
    static let ink = Color(red: 0.12, green: 0.13, blue: 0.13)
    static let secondary = Color(red: 0.36, green: 0.39, blue: 0.39)
    static let muted = Color(red: 0.52, green: 0.55, blue: 0.55)
    static let panel = Color(red: 0.95, green: 0.96, blue: 0.94)
    static let card = Color(red: 0.99, green: 0.995, blue: 0.985)
    static let blue = Color(red: 0.26, green: 0.39, blue: 0.46)
    static let green = Color(red: 0.34, green: 0.50, blue: 0.37)
    static let amber = Color(red: 0.64, green: 0.45, blue: 0.19)
    static let stroke = Color.black.opacity(0.08)
    static let hairline = Color.white.opacity(0.82)
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
                .strokeBorder(.white.opacity(0.78), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 30, x: 0, y: 18)
        .animation(.smooth(duration: 0.22), value: store.viewMode)
        .animation(.smooth(duration: 0.18), value: store.runState)
    }
}

struct LiquidSurface: View {
    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)

            LinearGradient(
                colors: [
                    ArkivStyle.panel.opacity(0.97),
                    Color(red: 0.90, green: 0.94, blue: 0.93).opacity(0.94),
                    Color(red: 0.97, green: 0.97, blue: 0.94).opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.42), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .blendMode(.softLight)
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
                .font(.system(size: 11, weight: .semibold))
                .tracking(3.4)
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
            .background(ArkivStyle.card.opacity(0.72), in: Circle())
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
            Spacer(minLength: 2)

            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(ArkivStyle.blue)
                .frame(width: 56, height: 56)
                .background(ArkivStyle.card.opacity(0.74), in: Circle())
                .overlay {
                    Circle().stroke(ArkivStyle.hairline, lineWidth: 1)
                }

            TextField("", text: $store.targetName, prompt: Text("Batch name").foregroundStyle(ArkivStyle.muted))
                .textFieldStyle(.plain)
                .focused($focused)
                .font(.system(size: 20, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(ArkivStyle.ink)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(GlassCard(cornerRadius: 16, opacity: 0.34))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(focused ? ArkivStyle.blue.opacity(0.42) : Color.clear, lineWidth: 1.5)
                }

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
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ArkivStyle.blue)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.68), in: Circle())

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ArkivStyle.ink)
                    .frame(width: 42, alignment: .leading)

                Text(path)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ArkivStyle.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 2)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ArkivStyle.muted)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(GlassCard(cornerRadius: 15, opacity: 0.26))
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
                    Text(label(for: duration))
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
                .buttonStyle(.plain)
                .foregroundStyle(store.monitorDuration == duration ? .white : ArkivStyle.secondary)
                .background(store.monitorDuration == duration ? ArkivStyle.ink.opacity(0.92) : Color.white.opacity(0.58), in: Capsule())
                .help(duration.rawValue)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.045), in: Capsule())
    }

    private func label(for duration: MonitorDuration) -> String {
        switch duration {
        case .fifteen: "15m"
        case .thirty: "30m"
        case .hour: "1h"
        case .infinite: "∞"
        }
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
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ArkivStyle.secondary)

            Slider(value: $store.rescueMinutes, in: 5...45, step: 5)
                .tint(ArkivStyle.blue)

            Text("\(Int(store.rescueMinutes))m")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ArkivStyle.secondary)
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(GlassCard(cornerRadius: 15, opacity: 0.22))
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
                    .font(.system(size: 21, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(ArkivStyle.ink)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ArkivStyle.secondary)
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
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ArkivStyle.ink)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(ArkivStyle.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background(GlassCard(cornerRadius: 13, opacity: 0.24))
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
                    .foregroundStyle(ArkivStyle.secondary)

                TextField(store.filter == .custom ? "jpg,png,mp4" : "Search filename", text: store.filter == .custom ? $store.customExtensions : $store.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: store.filter == .custom ? .monospaced : .default))
                    .foregroundStyle(ArkivStyle.ink)
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(GlassCard(cornerRadius: 13, opacity: 0.24))
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
        .background(store.filter == kind ? ArkivStyle.ink.opacity(0.92) : Color.white.opacity(0.58), in: Capsule())
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
        .foregroundStyle(ArkivStyle.secondary)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(GlassCard(cornerRadius: 16, opacity: 0.24))
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
                    .foregroundStyle(file.isSelected ? ArkivStyle.blue : ArkivStyle.muted)
            }
            .padding(.horizontal, 9)
            .frame(height: 44)
            .background(GlassCard(cornerRadius: 14, opacity: file.isSelected ? 0.32 : 0.22))
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
                .background(GlassCard(cornerRadius: 35, opacity: 0.28))

            VStack(spacing: 7) {
                Text("Archived")
                    .font(.system(size: 24, weight: .semibold))

                if let batch = store.lastArchive {
                    Text("\(batch.records.count) files")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ArkivStyle.secondary)

                    Text(batch.destinationFolder)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(ArkivStyle.secondary)
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
        let fillOpacity = min(0.96, 0.58 + opacity)

        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(ArkivStyle.card.opacity(fillOpacity))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(ArkivStyle.stroke, lineWidth: 0.8)
            }
            .shadow(color: .white.opacity(0.46), radius: 8, x: -2, y: -2)
            .shadow(color: .black.opacity(0.045), radius: 10, x: 0, y: 5)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isEnabled ? .white : ArkivStyle.secondary)
            .frame(height: 46)
            .background(
                isEnabled
                    ? ArkivStyle.ink.opacity(configuration.isPressed ? 0.82 : 0.94)
                    : ArkivStyle.card.opacity(0.78),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isEnabled ? Color.clear : ArkivStyle.stroke, lineWidth: 0.8)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ArkivStyle.secondary)
            .background(GlassCard(cornerRadius: 13, opacity: configuration.isPressed ? 0.34 : 0.22))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

struct GlassTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(ArkivStyle.secondary)
            .background(GlassCard(cornerRadius: 14, opacity: configuration.isPressed ? 0.32 : 0.22))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct GlassWideButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(ArkivStyle.ink)
            .frame(height: 46)
            .background(GlassCard(cornerRadius: 16, opacity: configuration.isPressed ? 0.34 : 0.24))
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
