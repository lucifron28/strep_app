# Strep MP3 Player

A sleek, Dracula-themed MP3 player for Android built with Flutter.

## Features

- 🎵 **Local MP3 Playback**: Play MP3 files stored on your device
- 🎨 **Complete Dracula Theme**: Beautiful dark theme with gradients, purple, pink, cyan, and green accents
- 🖼️ **Large Vinyl Disk SVG Backgrounds**: Subtle, decorative vinyl disks in the background for a unique music vibe
- 🗂️ **All Songs, Albums, and Artists Tabs**: Browse your music by song, album, or artist with modern expansion tiles
- 🖼️ **Editable Thumbnails**: Change song artwork with image picker (with Android 13+ permission support)
- ⏯️ **Full Playback Controls**: Play, pause, skip, seek, and progress tracking
- 💾 **Persistent State**: Remembers your library and resumes playback from last position
- 🧠 **Smart Storage**: Songs and metadata are saved using SharedPreferences
- 🧩 **Modern UI**: Clean, gradient backgrounds, rounded corners, and beautiful Dracula typography
- 🎧 **Now Playing Screen**: Full-screen player with enhanced text, progress bar, and controls
- 📂 **File Picker**: Import MP3 files from any location
- 🗑️ **Delete & Edit**: Remove or edit song details from your library

## Tech Stack

- **Flutter SDK**: Cross-platform mobile development
- **just_audio**: High-performance audio playback
- **permission_handler**: Storage and image picker permissions
- **file_picker**: File browsing and selection
- **provider**: State management
- **shared_preferences**: Data persistence

## Dracula Color Palette

- Background: `#282a36`
- Foreground: `#f8f8f2`
- Purple: `#bd93f9`
- Pink: `#ff79c6`
- Cyan: `#8be9fd`
- Green: `#50fa7b`
- Comment: `#6272a4`

## Setup Instructions

### Prerequisites

1. Flutter SDK (3.10.0 or higher recommended)
2. Android Studio or VS Code with Flutter extensions
3. Android device or emulator (API 21+)

### Installation

1. **Clone the repository**:
   ```bash
   git clone <your-repo-url>
   cd strep_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   # Or build APK
   flutter build apk --release
   ```

## Usage

### First Launch

1. **Grant Permissions**: The app will request storage and image permissions on first launch
2. **Import Music**: Use the add (+) button to import MP3 files
3. **Browse Your Library**: Switch between All Songs, Albums, and Artists tabs
4. **Play Music**: Tap any song to start playback

### Main Features

- **All Songs Tab**: List of all imported MP3s with play status and artwork
- **Albums Tab**: Grouped by album, with vinyl disk icons and expansion tiles
- **Artists Tab**: Grouped by artist, with gradient avatars and expansion tiles
- **Mini Player**: Persistent at the bottom for quick controls
- **Now Playing**: Full-screen player with enhanced progress bar and Dracula gradients
- **Edit/Delete**: Long-press or use the three-dots menu to edit or remove songs
- **Vinyl Disk Backgrounds**: Large, subtle SVG vinyls decorate the background

## Project Structure

```
lib/
├── main.dart
├── models/
│   └── song.dart
├── providers/
│   └── music_provider.dart
├── screens/
│   ├── music_list_screen.dart   # Main screen with tabs and vinyl backgrounds
│   ├── now_playing_screen.dart  # Full player UI with vinyl background
├── services/
│   ├── audio_player_service.dart
│   ├── music_service.dart
│   ├── song_storage_service.dart
│   └── image_service.dart
├── theme/
│   └── dracula_theme.dart
├── widgets/
│   ├── song_thumbnail.dart
│   ├── strep_icon.dart
│   ├── vinyl_disk.dart          # Vinyl SVG widget for backgrounds and icons
│   └── song_options_bottom_sheet.dart
└── test/
    └── widget_test.dart
```

## Permissions

The app requires the following Android permissions:
- `READ_EXTERNAL_STORAGE` / `MANAGE_EXTERNAL_STORAGE`: Access music files (Android 11+)
- `WRITE_EXTERNAL_STORAGE`: Cache and metadata (legacy)
- `WAKE_LOCK`: Prevent sleep during playback
- `FOREGROUND_SERVICE`: Background audio playback
- `READ_MEDIA_IMAGES`: For picking custom artwork (Android 13+)

## Troubleshooting

### No Music Found
- Import music using the add (+) button
- Grant all requested permissions
- Try the refresh button if your library is empty

### Playback Issues
- Verify MP3 files aren't corrupted
- Restart the app if audio stops working
- Check device volume and audio settings

### Permission Issues
- Go to device Settings > Apps > Strep > Permissions
- Enable all storage and media permissions

## Development

### Ideas for Future Features
- Audio visualizations
- Playlist management
- Audio effects/equalizer
- Lyrics display
- Metadata editing

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Dracula Theme: https://draculatheme.com/
- Flutter Team: https://flutter.dev/
- just_audio plugin: https://pub.dev/packages/just_audio
