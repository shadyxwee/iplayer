# VortexTube (Android TV & Leanback IPTV / Stalker Portal Player)

VortexTube is a high-performance, personalized IPTV and Stalker (Ministra) portal player designed specifically for Android TV and 10-foot Leanback displays.

---

## 📺 Project Structure

```
VortexTube/
├── UI/
│   └── Settings.html          # Reference HTML mockup for TV OS Settings
├── backend/                   # High-performance Rust backend engine
│   ├── Cargo.toml
│   └── src/
│       ├── bridge/            # C-ABI export interface for Flutter FFI
│       ├── db/                # SQLite metadata cache
│       ├── epg/               # XMLTV EPG parser
│       ├── personalization/   # Scoring & feed ranker engine
│       ├── player_support/    # Stream protocol utilities
│       └── sources/           # M3U parser, Xtream Codes, and Stalker client
├── app/                       # Android TV Flutter frontend
│   ├── android/               # Leanback launcher & Android TV configuration
│   ├── lib/
│   │   ├── bridge/            # Dart FFI bindings & pure-Dart fallbacks
│   │   ├── core/              # Models, StorageService, Theme, Image Cache
│   │   ├── features/
│   │   │   ├── home/          # VortexTube personalized feed with D-pad navigation
│   │   │   └── settings/      # 2-column TV OS Settings matching Settings.html & image.png
│   │   └── main.dart
│   └── test/                  # Unit and integration tests
└── README.md                  # This file
```

---

## 🚀 Key Features

1. **Stalker / Ministra Portal Client Specification (v1.0)**:
   - Full MAC Player and MAC Checker modes.
   - Dynamic URL endpoint auto-detection (`/portal.php`, `/c/portal.php`, `/stalker_portal/server/load.php`, `/server/load.php`, `/stalker_portal/c/portal.php`).
   - MAG200 STB headers (`User-Agent`, `Referer`, `mac`, `stb_lang`, `timezone`, `token`).
   - Token handshake, profile querying, category listing, stream command cleaning (`ffmpeg `, `auto ` prefixes).

2. **VortexTube Personalization Engine**:
   - Focuses strictly on user-loved categories and favorited channels/movies/series.
   - Live TV circular badges & Movie/Series 2:3 poster cards.
   - Smooth skeleton loading and empty state guidance directing users to Settings.

3. **10-Foot Leanback Settings UI (`Settings.html` & `image.png` match)**:
   - 2-Column TV OS Layout:
     - Left Categories: *Add to VortexTube*, *Playlists Manager*, *EPG & TV Guide*, *About VortexTube*.
     - Right Detail Panels:
       - **Add to VortexTube**: Live TV, Movies, and TV Series sub-tabs with active green checkmarks and toggle controls.
       - **Playlists Manager**: Active/Inactive playlist list with *Edit Portal* and *Use Portal* action buttons; *Add/Edit Portal Wizard* supporting Xtream Codes, M3U Playlist, and Stalker / Ministra MAC portal switcher.
       - **EPG & TV Guide**: Cache status, timeline window, and manual sync action.
       - **About VortexTube**: App version, build info, and update checks.
   - TV Remote Legend at the bottom showing D-Pad directions, Select, and Back buttons.

---

## 🛠️ Building & Running

### Prerequisites

- **Flutter SDK**: 3.16+
- **Rust toolchain & Cargo**: 1.70+
- **Android SDK & NDK** (for Android TV APK builds)

### 1. Build & Test Rust Backend

```bash
cd VortexTube/backend
cargo test
cargo build --release
```

### 2. Run Flutter App & Tests

```bash
cd VortexTube/app
flutter test
flutter run
```

### 3. Build Android TV APK

```bash
cd VortexTube/app
flutter build apk --release
```

The compiled Android TV Leanback APK will be located at:
`VortexTube/app/build/app/outputs/flutter-apk/app-release.apk`
