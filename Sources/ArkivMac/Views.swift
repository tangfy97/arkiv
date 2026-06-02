import SwiftUI

private struct ArkivTheme {
    let scheme: ColorScheme

    var isDark: Bool { scheme == .dark }
    var text: Color { isDark ? .white.opacity(0.94) : .black.opacity(0.86) }
    var secondary: Color { isDark ? .white.opacity(0.62) : Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.58) }
    var tertiary: Color { isDark ? .white.opacity(0.34) : Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.34) }
    var quaternary: Color { isDark ? .white.opacity(0.20) : Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.18) }
    var separator: Color { isDark ? .white.opacity(0.10) : Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.11) }
    var separatorStrong: Color { isDark ? .white.opacity(0.16) : Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.18) }
    var fill: Color { isDark ? Color(red: 0.47, green: 0.48, blue: 0.51).opacity(0.26) : Color(red: 0.46, green: 0.46, blue: 0.50).opacity(0.12) }
    var fillHover: Color { isDark ? Color(red: 0.51, green: 0.52, blue: 0.55).opacity(0.38) : Color(red: 0.46, green: 0.46, blue: 0.50).opacity(0.20) }
    var input: Color { isDark ? .white.opacity(0.06) : .white.opacity(0.70) }
    var inputBorder: Color { isDark ? .white.opacity(0.10) : .black.opacity(0.10) }
    var panelSurface: Color { isDark ? Color(red: 0.15, green: 0.15, blue: 0.17).opacity(0.66) : Color(red: 0.97, green: 0.97, blue: 0.98).opacity(0.74) }
    var panelBorder: Color { isDark ? .white.opacity(0.12) : .black.opacity(0.08) }
    var panelTop: Color { isDark ? .white.opacity(0.16) : .white.opacity(0.85) }
    var toolbarBackground: Color { isDark ? Color(red: 0.19, green: 0.19, blue: 0.22).opacity(0.55) : .white.opacity(0.42) }
    var accent: Color { isDark ? Color(red: 0.24, green: 0.80, blue: 0.53) : Color(red: 0.12, green: 0.56, blue: 0.35) }
    var accentSoft: Color { accent.opacity(isDark ? 0.20 : 0.13) }
    var danger: Color { isDark ? Color(red: 1.0, green: 0.45, blue: 0.42) : Color(red: 0.78, green: 0.16, blue: 0.13) }
    var image: Color { isDark ? Color(red: 0.36, green: 0.79, blue: 0.75) : Color(red: 0.17, green: 0.60, blue: 0.58) }
    var video: Color { isDark ? Color(red: 0.65, green: 0.61, blue: 0.95) : Color(red: 0.48, green: 0.42, blue: 0.86) }
    var other: Color { isDark ? Color(red: 0.72, green: 0.67, blue: 0.63) : Color(red: 0.55, green: 0.51, blue: 0.46) }
    var radius: CGFloat { 18 }
    var innerRadius: CGFloat { 10 }
}

struct RootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        ZStack {
            RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                .fill(theme.panelSurface)

            RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [theme.panelTop, .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .blendMode(.softLight)

            VStack(spacing: 0) {
                switch store.viewMode {
                case .ready:
                    SetupPanel()
                case .watching:
                    MonitoringPanel()
                case .archived:
                    ArchivedPanel()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                .strokeBorder(theme.panelBorder, lineWidth: 0.5)
        }
        .shadow(
            color: theme.isDark ? .black.opacity(0.55) : Color(red: 0.08, green: 0.11, blue: 0.15).opacity(0.22),
            radius: theme.isDark ? 56 : 44,
            x: 0,
            y: theme.isDark ? 18 : 16
        )
        .animation(.smooth(duration: 0.20), value: store.viewMode)
    }
}

private struct Toolbar: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: SessionStore

    let title: String
    var showsStatus = false
    var trailing: AnyView

    init<Content: View>(title: String, showsStatus: Bool = false, @ViewBuilder trailing: () -> Content) {
        self.title = title
        self.showsStatus = showsStatus
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        ZStack(alignment: .top) {
            Rectangle()
                .fill(theme.toolbarBackground)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(theme.separator)
                        .frame(height: 0.5)
                }

            Capsule()
                .fill(theme.quaternary)
                .frame(width: 34, height: 5)
                .padding(.top, 8)

            HStack(spacing: 9) {
                if showsStatus {
                    StatusDot(paused: store.runState == .paused)
                }

                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .tracking(-0.25)
                    .foregroundStyle(theme.text)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                trailing
            }
            .padding(.top, 20)
            .padding(.horizontal, 12)
            .padding(.bottom, 11)
        }
        .frame(height: 58)
        .contentShape(Rectangle())
    }
}

private struct StatusDot: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var pulse = false
    let paused: Bool

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)
        let color = paused ? Color.orange : theme.accent

        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .scaleEffect(pulse && !paused ? 1.35 : 1)
            .opacity(pulse && !paused ? 0.62 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

private struct SetupPanel: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: SessionStore
    @State private var durationOpen = false

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        VStack(spacing: 0) {
            Toolbar(title: "Set up") {
                IconCircleButton(systemName: "xmark", title: "Quit Arkiv") {
                    NSApp.terminate(nil)
                }
            }

            ScrollView {
                VStack(spacing: 14) {
                    GroupBox(label: "Batch") {
                        GroupRow(label: "Name") {
                            TextField("", text: $store.targetName, prompt: Text("Required").foregroundStyle(theme.tertiary))
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(theme.text)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 170)
                        }
                    }

                    GroupBox(label: "Folders") {
                        GroupRow(
                            label: "Watch",
                            value: store.watchFolderURL.lastPathComponent,
                            leading: Image(systemName: "folder").foregroundStyle(theme.accent),
                            action: { store.chooseWatchFolder() }
                        )

                        DividerLine()

                        GroupRow(
                            label: "Archive to",
                            value: store.archiveRootURL.lastPathComponent,
                            leading: Image(systemName: "arrow.down.to.line").foregroundStyle(theme.accent),
                            action: { store.chooseArchiveRoot() }
                        )
                    }

                    GroupBox(label: "Monitoring") {
                        GroupRow(label: "Duration", value: store.monitorDuration.fullLabel, action: {
                            durationOpen.toggle()
                        })

                        if durationOpen {
                            VStack(spacing: 8) {
                                DividerLine()
                                DurationSegmented()
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 12)
                            }
                        }

                        DividerLine()

                        GroupRow(label: "Include recent files", subtitle: "Catch files added just before you started.") {
                            Toggle("", isOn: $store.includeRescueMode)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }

                        if store.includeRescueMode {
                            VStack(alignment: .leading, spacing: 7) {
                                DividerLine()
                                Text("From the last")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(theme.secondary)
                                    .padding(.horizontal, 12)
                                RecentSegmented()
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 12)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)

            BottomActionArea {
                PillButton(systemName: "play.fill", title: "Start monitoring", disabled: store.targetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    store.startSession()
                }
            }
        }
    }
}

private struct DurationSegmented: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        Picker("Duration", selection: $store.monitorDuration) {
            ForEach(MonitorDuration.allCases) { duration in
                Text(duration.rawValue).tag(duration)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.small)
    }
}

private struct RecentSegmented: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        Picker("Recent files", selection: $store.recentWindow) {
            ForEach(RecentWindow.allCases) { window in
                Text(window.rawValue).tag(window)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.small)
    }
}

private struct MonitoringPanel: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        VStack(spacing: 0) {
            Toolbar(title: store.sanitizedTargetName, showsStatus: true) {
                HStack(spacing: 6) {
                    IconCircleButton(systemName: store.runState == .paused ? "play.fill" : "pause.fill", title: store.runState == .paused ? "Resume" : "Pause") {
                        store.togglePause()
                    }
                    IconCircleButton(systemName: "xmark.circle", title: "Cancel", role: .destructive) {
                        store.cancelSession()
                    }
                }
            }

            VStack(spacing: 10) {
                StatPillBar()

                HStack(spacing: 8) {
                    SearchField()
                    FilterMenu()
                }

                if store.filter == .custom {
                    SearchField(custom: true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            HStack {
                SectionLabel(store.searchText.isEmpty && store.filter == .all ? "Detected files" : "\(store.filteredFiles.count) matching")
                Spacer()
                Button(store.allFilteredReadySelected ? "Deselect all" : "Select all") {
                    store.toggleAllFilteredReady()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.accent)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 6)

            ScrollView {
                VStack(spacing: 0) {
                    if store.filteredFiles.isEmpty {
                        Text(store.statusMessage == "Ready" ? "No files match." : store.statusMessage)
                            .font(.system(size: 12.5, weight: .regular))
                            .foregroundStyle(theme.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 26)
                    } else {
                        ForEach(Array(store.filteredFiles.enumerated()), id: \.element.id) { index, file in
                            if index > 0 {
                                DividerLine(inset: 47)
                            }
                            FileRow(file: file)
                                .padding(.horizontal, 4)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: theme.innerRadius, style: .continuous)
                        .fill(theme.input)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: theme.innerRadius, style: .continuous)
                        .strokeBorder(theme.inputBorder, lineWidth: 0.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: theme.innerRadius, style: .continuous))
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 14)

            BottomActionArea {
                PillButton(
                    systemName: "archivebox.fill",
                    title: store.selectedReadyFiles.isEmpty ? "Select files to archive" : "Archive selected",
                    count: store.selectedReadyFiles.isEmpty ? nil : store.selectedReadyFiles.count,
                    disabled: store.selectedReadyFiles.isEmpty
                ) {
                    store.archiveSelected()
                }
            }
        }
    }
}

private struct ArchivedPanel: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)
        let batch = store.lastArchive

        VStack(spacing: 0) {
            Toolbar(title: "Archived") {
                IconCircleButton(systemName: "xmark", title: "Quit Arkiv") {
                    NSApp.terminate(nil)
                }
            }

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(theme.accentSoft)
                            .frame(width: 54, height: 54)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 27, weight: .semibold))
                                    .foregroundStyle(theme.accent)
                            }
                            .transition(.scale)

                        Text("\(batch?.records.count ?? 0) \(batch?.records.count == 1 ? "file" : "files") archived")
                            .font(.system(size: 21, weight: .semibold))
                            .tracking(-0.35)
                            .foregroundStyle(theme.text)
                            .padding(.top, 14)

                        Text("Sorted and moved out of \(store.watchFolderURL.lastPathComponent).")
                            .font(.system(size: 12.5, weight: .regular))
                            .foregroundStyle(theme.secondary)
                            .padding(.top, 3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                    GroupBox(label: "Destination") {
                        GroupRow(
                            label: batch?.destinationFolder.shortHomePath ?? store.archiveRootDisplayName,
                            leading: Image(systemName: "folder").foregroundStyle(theme.accent)
                        )
                    }

                    GroupBox(label: "Breakdown") {
                        BreakdownRow(label: "Images", value: batch?.imageCount ?? 0, systemName: "photo", color: theme.image)
                        DividerLine()
                        BreakdownRow(label: "Videos", value: batch?.videoCount ?? 0, systemName: "video", color: theme.video)
                        DividerLine()
                        BreakdownRow(label: "Other", value: batch?.otherCount ?? 0, systemName: "doc", color: theme.other)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 22)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)

            BottomActionArea(alignment: .horizontal) {
                GhostButton(systemName: "arrow.uturn.backward", title: "Undo") {
                    store.undoLastArchive()
                }
                PillButton(systemName: "plus", title: "New batch") {
                    store.beginNewSession()
                }
            }
        }
    }
}

private struct GroupBox<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        VStack(alignment: .leading, spacing: 7) {
            SectionLabel(label)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(theme.input)
            .overlay {
                RoundedRectangle(cornerRadius: theme.innerRadius, style: .continuous)
                    .strokeBorder(theme.inputBorder, lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.innerRadius, style: .continuous))
        }
    }
}

private struct GroupRow<Leading: View, Control: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    var subtitle: String?
    var value: String?
    var leading: Leading
    var action: (() -> Void)?
    var control: Control

    init(
        label: String,
        subtitle: String? = nil,
        value: String? = nil,
        leading: Leading,
        action: (() -> Void)? = nil,
        @ViewBuilder control: () -> Control
    ) {
        self.label = label
        self.subtitle = subtitle
        self.value = value
        self.leading = leading
        self.action = action
        self.control = control()
    }

    var body: some View {
        if let action {
            Button(action: action) {
                rowContent
            }
            .buttonStyle(.plain)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        return HStack(spacing: 10) {
            leading
                .font(.system(size: 17, weight: .regular))
                .frame(width: leadingFrame)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.text)
                    .lineLimit(1)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(theme.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            control

            if let value {
                Text(value)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(theme.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 150, alignment: .trailing)
            }

            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, subtitle == nil ? 8 : 9)
        .frame(minHeight: 42)
        .contentShape(Rectangle())
    }

    private var leadingFrame: CGFloat {
        Leading.self == EmptyView.self ? 0 : 18
    }
}

private extension GroupRow where Leading == EmptyView, Control == EmptyView {
    init(label: String, subtitle: String? = nil, value: String? = nil, action: (() -> Void)? = nil) {
        self.init(label: label, subtitle: subtitle, value: value, leading: EmptyView(), action: action) {
            EmptyView()
        }
    }
}

private extension GroupRow where Leading == EmptyView {
    init(label: String, subtitle: String? = nil, value: String? = nil, action: (() -> Void)? = nil, @ViewBuilder control: () -> Control) {
        self.init(label: label, subtitle: subtitle, value: value, leading: EmptyView(), action: action, control: control)
    }
}

private extension GroupRow where Control == EmptyView {
    init(label: String, subtitle: String? = nil, value: String? = nil, leading: Leading, action: (() -> Void)? = nil) {
        self.init(label: label, subtitle: subtitle, value: value, leading: leading, action: action) {
            EmptyView()
        }
    }
}

private struct BreakdownRow: View {
    let label: String
    let value: Int
    let systemName: String
    let color: Color

    var body: some View {
        GroupRow(label: label, value: "\(value)", leading: Image(systemName: systemName).foregroundStyle(color))
    }
}

private struct SectionLabel: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(theme.tertiary)
    }
}

private struct StatPillBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        HStack(spacing: 0) {
            StatCell(value: store.detectedCount, label: "Detected", accent: false)
            Rectangle().fill(theme.separator).frame(width: 0.5)
            StatCell(value: store.readyCount, label: "Ready", accent: false)
            Rectangle().fill(theme.separator).frame(width: 0.5)
            StatCell(value: store.selectedCount, label: "Selected", accent: true)
        }
        .background(theme.fill)
        .overlay {
            RoundedRectangle(cornerRadius: theme.innerRadius, style: .continuous)
                .strokeBorder(theme.separator, lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.innerRadius, style: .continuous))
    }
}

private struct StatCell: View {
    @Environment(\.colorScheme) private var colorScheme
    let value: Int
    let label: String
    let accent: Bool

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 17, weight: .semibold))
                .monospacedDigit()
                .tracking(-0.25)
                .foregroundStyle(accent ? theme.accent : theme.text)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(accent ? theme.accent : theme.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(accent ? theme.accentSoft : Color.clear)
    }
}

private struct SearchField: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: SessionStore
    var custom = false

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)
        let binding = custom ? $store.customExtensions : $store.searchText

        HStack(spacing: 8) {
            Image(systemName: custom ? "slider.horizontal.3" : "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.secondary)

            TextField(custom ? "Extension, e.g. psd" : "Search files", text: binding)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(theme.text)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(theme.input)
        .overlay {
            RoundedRectangle(cornerRadius: theme.innerRadius, style: .continuous)
                .strokeBorder(theme.inputBorder, lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.innerRadius, style: .continuous))
    }
}

private struct FilterMenu: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        Menu {
            ForEach(MediaKind.allCases) { kind in
                Button {
                    store.filter = kind
                } label: {
                    Label(kind == .all ? "All types" : kind.rawValue, systemImage: kind.menuSymbol)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: store.filter.menuSymbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.accent)
                Text(store.filter == .all ? "All types" : store.filter.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.text)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.tertiary)
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(theme.input)
            .overlay {
                RoundedRectangle(cornerRadius: theme.innerRadius, style: .continuous)
                    .strokeBorder(theme.inputBorder, lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.innerRadius, style: .continuous))
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct FileRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: SessionStore
    let file: DetectedFile

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)
        let selectable = file.readiness == .ready

        Button {
            if selectable {
                store.toggleSelection(for: file)
            }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: file.kind.fileSymbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(file.kind.typeColor(theme))
                    .frame(width: 28, height: 28)
                    .background(file.kind.typeColor(theme).opacity(theme.isDark ? 0.22 : 0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(file.url.deletingPathExtension().lastPathComponent)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(theme.text)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text(file.fileExtension.uppercased().isEmpty ? "FILE" : file.fileExtension.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(theme.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(theme.fill)
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 6) {
                        Text(file.sizeBytes.arkivByteString)
                            .monospacedDigit()
                        Text("·")
                        if file.readiness == .ready {
                            Text("Ready")
                        } else if file.readiness == .missing {
                            Text("Missing")
                        } else {
                            ProgressView()
                                .controlSize(.mini)
                                .scaleEffect(0.55)
                                .frame(width: 11, height: 11)
                            Text("Copying…")
                        }
                    }
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(file.readiness == .ready ? theme.secondary : theme.tertiary)
                }

                Spacer(minLength: 8)

                if selectable {
                    Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(file.isSelected ? theme.accent : theme.tertiary)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 40)
            .background(file.isSelected && selectable ? theme.accentSoft : Color.clear)
            .opacity(selectable ? 1 : 0.72)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
    }
}

private struct PillButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let systemName: String
    let title: String
    var count: Int?
    var disabled = false
    let action: () -> Void

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                if let count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(disabled ? theme.tertiary : theme.accent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(disabled ? theme.fill : Color.white.opacity(0.88))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(disabled ? theme.tertiary : .white)
            .padding(.horizontal, 19)
            .frame(height: 44)
            .background(disabled ? theme.fill : theme.accent)
            .clipShape(Capsule())
            .shadow(color: disabled ? .clear : theme.accent.opacity(0.22), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

private struct GhostButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let systemName: String
    let title: String
    let action: () -> Void

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.text)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(theme.fill)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct IconCircleButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let systemName: String
    let title: String
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)

        Button(role: role, action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(role == .destructive ? theme.danger : theme.secondary)
                .frame(width: 26, height: 26)
                .background(theme.fill)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help(title)
    }
}

private enum BottomActionAlignment {
    case centered
    case horizontal
}

private struct BottomActionArea<Content: View>: View {
    var alignment: BottomActionAlignment = .centered
    @ViewBuilder var content: Content

    var body: some View {
        Group {
            if alignment == .horizontal {
                HStack(spacing: 10) {
                    content
                }
            } else {
                HStack {
                    Spacer()
                    content
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }
}

private struct DividerLine: View {
    @Environment(\.colorScheme) private var colorScheme
    var inset: CGFloat = 13

    var body: some View {
        let theme = ArkivTheme(scheme: colorScheme)
        Rectangle()
            .fill(theme.separator)
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}

private extension MediaKind {
    var menuSymbol: String {
        switch self {
        case .all: "square.grid.2x2"
        case .image: "photo"
        case .video: "video"
        case .other: "doc"
        case .custom: "slider.horizontal.3"
        }
    }

    var fileSymbol: String {
        switch self {
        case .image: "photo"
        case .video: "video"
        case .other, .custom, .all: "doc"
        }
    }

    func typeColor(_ theme: ArkivTheme) -> Color {
        switch self {
        case .image: theme.image
        case .video: theme.video
        case .other, .custom, .all: theme.other
        }
    }
}

private extension String {
    var shortHomePath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if self == home {
            return "~"
        }
        if hasPrefix(home + "/") {
            return "~" + dropFirst(home.count)
        }
        return self
    }
}
