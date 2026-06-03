# Arkiv Native V1

This is the first native macOS rewrite of Arkiv. It keeps the quiet floating-panel language of the React prototype, but the core flow is now real:

- Watches `~/Downloads` with FSEvents.
- Lets you choose the folder to watch.
- Lets you choose the archive destination.
- Lets you monitor for 15 minutes, 30 minutes, 1 hour, or until you stop it.
- Supports pause, resume, cancel, and quit from the floating panel.
- Detects all regular files, not only media.
- Classifies files as images, videos, or other using extension and `UTType`.
- Supports filters: All types, Images, Videos, Other, and Custom extensions.
- Supports filename search and multi-select.
- Waits for files to become stable before marking them ready.
- Archives selected ready files into `{Archive Root}/{Subject}/{Set}/Images`, `Videos`, or `Other`.
- Suggests the next set automatically, such as `Set 002` when `Set 001` already exists.
- Lets you enter only the set number; Arkiv still creates folders like `Set 001`.
- Migrates old flat `{Subject}/Images`, `Videos`, and `Other` folders into `{Subject}/Set 001/` before archiving new sets.
- Writes a JSON ledger under `~/Pictures/Arkiv/.arkiv-ledger/`.
- Supports undo for the last archive batch.

Run it from this folder for development and debug:

```sh
swift run ArkivMac
```

Build a double-clickable app bundle:

```sh
scripts/build_app.sh debug
open dist/Arkiv.app
```

Use `swift run ArkivMac` when you want fast terminal debugging. Use `dist/Arkiv.app` when you want normal daily use without a terminal.

V1 is intentionally small. The next high-impact pass should add real thumbnails, duplicate detection, menu bar presence, global shortcuts, and persisted folder preferences.

## UI direction

The current native UI is a fixed-size floating glass panel. It intentionally avoids resizable dashboard behavior:

- 400 x 540 fixed floating window.
- Hidden traffic-light controls.
- Native `.ultraThinMaterial` glass backdrop with semantic light and dark colors.
- Layout B: compact macOS controls, grouped settings rows, grouped file list, and floating actions.
- Plain-language controls for monitoring duration and recent-file inclusion.
