# RIPTV - Next-Gen IPTV Player

A high-performance, cross-platform IPTV application engineered with a **Rust Core Engine** backend (`flutter_rust_bridge`) and a **Flutter UI Frontend** layer.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             FLUTTER UI LAYER                                │
│    Mobile (iOS/Android) | Desktop (Win/macOS/Linux) | Android TV / Fire TV   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Dart FFI (Zero-Copy)
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                            RUST CORE ENGINE                                 │
│  • M3U/M3U8 Fast Stream Parser            • Stalker/MAC Middleware Engine   │
│  • XMLTV EPG Decompression & Querying     • Token & Session Renewal         │
│  • Local Database (SQLite + FTS5 Indexing) • Xtream Codes API Driver        │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ FFI / Native Player Bindings
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                           NATIVE MEDIA ENGINE                               │
│           media_kit (libmpv) / ExoPlayer / AVPlayer / Hardware Decoders     │
└─────────────────────────────────────────────────────────────────────────────┘
```

The application separates business logic from the UI:
- **Rust Core Engine (`/rust`)**: Handles heavy off-thread operations including fast line-by-line M3U parsing, XMLTV `.xml.gz` decompression, Stalker/MAC portal handshake & session auto-renewal, and sub-millisecond channel lookups via an embedded SQLite database with **FTS5 full-text search**.
- **Flutter UI (`/lib`)**: Responsive presentation layer supporting Touch, Mouse, and 10-foot spatial D-Pad TV remote navigation.
- **Native Media Engine**: Powered by `media_kit` (libmpv/FFmpeg) with hardware decoding, low-latency live streaming buffers, and per-stream HTTP header injection.

---

## ✨ Features

### 📺 Playback & Video Engine
- **Hardware Accelerated Playback**: Smooth streaming for HLS (`.m3u8`), MPEG-TS (`.ts`), MP4, MKV, and RTMP streams.
- **Dynamic Stream Headers**: Automatic injection of custom `User-Agent`, `Referer`, and Stalker portal session cookies on a per-stream basis.
- **On-Screen Control Ribbon**: Auto-hiding 3-second media bar with seekbar, volume slider, audio track selector, subtitle track picker, and favorite toggle.
- **True Fullscreen Mode**: Auto-hiding OS chrome with double-tap/gesture toggle support.

### 🎯 Content & Account Onboarding
- **M3U / M3U8 Integration**: Zero-copy off-thread parsing for playlists exceeding 100,000+ entries.
- **Xtream Codes API**: Authenticate via `player_api.php`, dynamically fetching Live, Movie, and Series categories.
- **Stalker / MAC Portal Middleware**: Full MAC address (`00:1A:79:XX:XX:XX`) handshake emulation (MAG 250/254 STB device signatures) with automatic background session token renewal.
- **Global Favorites & Watch History**: Mark favorite streams and retain watch progress across playlists.

### 🔍 Search & EPG
- **SQLite + FTS5 Indexing**: Sub-millisecond fuzzy search across channel names, TVG IDs, and categories.
- **XMLTV Intake**: Background decompression and parsing for `.xml` and `.xml.gz` EPG feeds with channel schedule matching.

---

## 🛠️ Prerequisites & Setup

### Requirements
- **Flutter SDK**: 3.19.0 or higher
- **Rust Toolchain**: 1.75.0 or higher (`rustc`, `cargo`)
- **flutter_rust_bridge_codegen**: `cargo install flutter_rust_bridge_codegen`

---

## 🚀 Build Instructions

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/yourusername/iptv_player.git
cd iptv_player
```

### 2️⃣ Install Flutter & Rust Dependencies
```bash
flutter pub get
cd rust && cargo check && cd ..
```

### 3️⃣ Generate Rust FFI Bridge & Schemas
```bash
flutter_rust_bridge_codegen generate
dart run build_runner build --delete-conflicting-outputs
```

### 4️⃣ Run Tests
Run both Dart UI tests and Rust backend core unit tests:
```bash
# Test Rust Backend Core Engine
cd rust && cargo test && cd ..

# Test Flutter UI Frontend
flutter test
```

### 5️⃣ Run the Application

**Development Mode:**
```bash
flutter run -d windows # Or linux, macos, android
```

**Build Release:**
```bash
flutter build windows --release
```

The release executable will be located in `build/windows/x64/runner/Release/iptv_player.exe`.

---

## 📁 Repository Structure

```
iptv_player/
├── claude.md                    # Architecture & development rules for AI assistants
├── agent.md                     # Agent task execution workflow rules
├── .cursorrules                 # Rules for Cursor IDE
├── pubspec.yaml                 # Flutter package manifest
├── lib/
│   ├── models/                  # Data structures (Channel, Playlist, Series)
│   ├── services/                # Dart wrappers & Rust FFI service bridges
│   ├── screens/                 # VORTEX UI screens (Dashboard, Live TV, Movies, Series, Player)
│   ├── widgets/                 # Custom vector graphics & UI widgets
│   └── main.dart                # Application entrypoint
└── rust/                        # Rust Core Engine workspace
    ├── Cargo.toml               # Rust crate manifest
    └── src/
        ├── api.rs               # FFI exported bridge functions
        ├── db.rs                # SQLite + FTS5 database persistence pool
        ├── m3u.rs               # Zero-copy fast line-by-line M3U parser
        ├── epg.rs               # XMLTV decompressor and XML stream parser
        └── stalker.rs           # Stalker/MAC portal handshake & token renewal
```

---

## 📄 License

This project is licensed under the MIT License.
