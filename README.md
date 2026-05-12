# RIPTV

A professional IPTV playback application built with Flutter, inspired by TiviMate.

## ✨ Features

### 📺 Playback
- **Live TV**: View live channels with a 3-column interface (categories, channels, player)
- **VOD Movies**: Explore and play movies organized by categories
- **Series**: Navigate through seasons and episodes with detailed information
- **Advanced video controls**:
  - Progress bar with seeking
  - Quick skip: +10/-10 seconds
  - Volume control with slider
  - Multiple audio tracks
  - Configurable subtitles
  - **True fullscreen mode** (hides Windows taskbar)
  - Keyboard shortcuts (Space, Arrows, F/F11, Escape)

### 🎯 Content Management
- **M3U/M3U8 Support**: Import playlists from URL or local file
- **Xtream Codes Authentication**: Compatible with popular IPTV services
  - Full Xtream Codes API support
  - Lazy loading of series episodes (ultra-fast)
  - Automatic categories for Live TV, Movies, and Series
- **Multiple playlists**: Manage several lists simultaneously
- **Favorites system**: Mark your preferred channels and content
- **Advanced search**: Filter by name, category, or group

### 💾 Storage
- **Isar Database**: Ultra-fast and efficient local storage
- **Content caching**: Reduces loading time on subsequent launches
- **Offline access**: Access your history and favorites offline

### 🎨 Interface
- **Dynamic Theme System**: Switch between multiple themes instantly
  - **Original Theme**: Cyan/blue design inspired by TiviMate
  - **Netflix Theme**: Netflix-style with red/dark colors
  - Automatically saved preferences
- **Modern design**: Material Design 3 with Netflix-style layouts
- **Fully Responsive**: Adapts to mobile, tablet, and desktop
- **Multi-language**: English, Spanish, Chinese (简体中文), and Russian (Русский)
- **Adaptive Navigation**:
  - Mobile: Side menu (Drawer)
  - Tablet/Desktop: Full navigation bar

### ⭐ Ratings
- **Smart ratings**: 3-tier system for obtaining ratings
  - OMDb API (no key required)
  - TMDB API (optional)
  - Pseudo-random generator (automatic fallback)
- **Visual indicators**: Badges with colors based on rating
- **No limits**: The app works completely without configuring APIs

## 🛠️ Technologies Used

- **Flutter**: Cross-platform UI framework
- **media_kit**: Video player based on libmpv/FFmpeg
- **Isar**: High-speed local NoSQL database
- **Material Design 3**: Modern and adaptive design

## 🚀 Installation and Execution

### 1️⃣ Clone the repository
```bash
git clone https://github.com/yourusername/iptv_player.git
cd iptv_player
```

### 2️⃣ Install dependencies
```bash
flutter pub get
```

### 3️⃣ Generate Isar code
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4️⃣ Run the application

**Development mode:**
```bash
flutter run -d windows
```

**Build Release:**
```bash
flutter build windows --release
```

The executable will be at: `build\windows\x64\runner\Release\iptv_player.exe`

## 📁 Project Structure

```
lib/
├── models/                      # Data models
├── services/                    # Business logic
├── providers/                   # State management
├── screens/                     # UI Screens
├── widgets/                     # Reusable components
├── l10n/                        # Localization
└── main.dart                    # Entry point
```

## 📄 License

This project is licensed under the MIT License.
