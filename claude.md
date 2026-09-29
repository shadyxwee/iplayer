# IPTV Application - Architecture & Development Guidelines

## Project Overview
High-performance cross-platform IPTV application built with Flutter (Frontend UI), Rust (Core Processing Engine via `flutter_rust_bridge`), and `media_kit` (libmpv video playback backend).

## Core Principles
1. UI Responsiveness First: Never run heavy computation (M3U parsing, EPG XML processing, full-text database indexing) on the Dart main thread. Delegate all heavy tasks to the Rust core layer via FFI.
2. Dual Input Target: Design every screen to work seamlessly with both Touch/Mouse inputs AND spatial D-Pad TV remotes. Always explicitly specify spatial focus bindings.
3. Native Player Isolation: Rely on native video engine bindings (`media_kit`) for HLS/MPEG-TS streams to maintain hardware acceleration across Android, Windows, macOS, and Linux.

## Code Structure Guidelines

### Dart / Flutter (`/lib`)
- `lib/src/features/` - Feature-driven architecture (e.g., `live_tv`, `epg`, `vod`, `playlist`, `player`).
- `lib/src/core/` - Reusable services, app theme, database drivers, FFI bindings.
- Virtualization: Always use `ListView.builder` or `CustomScrollView` with virtualized slivers for channel lists and EPG grids.
- Focus System: Wrap interactive elements in custom focusable widgets that manage TV focus states explicitly (`Focus`, `FocusNode`).

### Rust Engine (`/rust`)
- `rust/src/api/` - Flutter Rust Bridge exposed APIs.
- `rust/src/m3u/` - Zero-copy M3U stream and playlist parsing.
- `rust/src/epg/` - XMLTV `.gz` decompressor and parser.
- `rust/src/stalker/` - Stalker/MAC portal handshake, session token renewal, and request signing.
- Memory Management: Avoid unnecessary cloning during stream parsing. Use string references or stream line-by-line into SQLite.

## Conventions & Commands
- Flutter Build: `flutter run -d [android|windows|macos|linux]`
- Rust Compilation / Bridge Generation: `flutter_rust_bridge_codegen generate`
- Run Tests: `flutter test` and `cargo test` inside `/rust` directory.
