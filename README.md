# Arkiv Native V1

This is the first native macOS rewrite of Arkiv. It keeps the quiet floating-panel language of the React prototype, but the core flow is now real:

- Watches `~/Downloads` with FSEvents.
- Lets you choose the folder to watch.
- Lets you choose the archive destination.
- Lets you monitor for 15 minutes, 30 minutes, 1 hour, or until stopped.
- Supports pause, resume, cancel, and quit from the floating panel.
- Detects all regular files, not only media.
- Classifies files as images, videos, or other using extension and `UTType`.
- Supports filters: All, Images, Videos, Other, and Custom extensions.
- Supports filename search and multi-select.
- Waits for files to become stable before marking them ready.
- Archives selected ready files into `{Archive Root}/{Target}/{Date Session}/Images`, `Videos`, or `Other`.
- Writes a JSON ledger under `~/Pictures/Arkiv/.arkiv-ledger/`.
- Supports undo for the last archive batch.

Run it from this folder:

```sh
swift run ArkivMac
```

V1 is intentionally small. The next high-impact pass should add real thumbnails, duplicate detection, menu bar presence, global shortcuts, persisted preferences, and a packaged `.app` target.

## UI direction

The current native UI is a fixed-size floating glass panel. It intentionally avoids resizable dashboard behavior:

- 386 x 520 fixed floating window.
- Hidden traffic-light controls.
- Native translucent material backdrop.
- Compact setup, watching, and archived states.
- Icon-first filters and one primary archive action.
