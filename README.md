# Strep MP3 Player

A sleek, Dracula-themed MP3 player for Android built with Flutter.

## Features

- 🎵 **Local MP3 Playback**: Play MP3 files stored on your device
- 🎨 **Dracula Theme**: Beautiful dark theme with purple, pink, and green accents
- 📱 **Modern UI**: Clean, minimalist interface focused on usability
- ⏯️ **Full Playback Controls**: Play, pause, skip, seek, and progress tracking
- 💾 **Persistent State**: Resumes playback from last position when app restarts
- 🎧 **Now Playing Screen**: Dedicated full-screen player with album art support
- 📂 **File Browser**: Browse and select MP3 files from your device

## Tech Stack

- **Flutter SDK**: Cross-platform mobile development
- **just_audio**: High-performance audio playback
- **permission_handler**: Storage access permissions
- **file_picker**: File browsing and selection
- **provider**: State management
- **shared_preferences**: Data persistence

## Dracula Color Palette

- Background: `#282a36`
- Foreground: `#f8f8f2`
- Purple: `#bd93f9`
- Pink: `#ff79c6`
- Green: `#50fa7b`
- Comment: `#6272a4`

## Setup Instructions

### Prerequisites

1. Flutter SDK (3.9.0 or higher)
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

3. **Configure Android permissions** (already done):
   - Storage permissions in `android/app/src/main/AndroidManifest.xml`
   - Required for accessing MP3 files on device

4. **Run the app**:
   ```bash
   # For debug mode
   flutter run

   # To build APK
   flutter build apk --release
   ```

## Usage

### First Launch

1. **Grant Permissions**: The app will request storage permissions on first launch
2. **Browse Files**: Tap "Browse Files" or the refresh button to select MP3 files
3. **Start Playing**: Tap any song in the list to start playback

### Main Features

- **Music List**: Displays all available MP3 files with play status indicators
- **Mini Player**: Shows current song info at the bottom with quick controls
- **Now Playing**: Tap the mini player to access the full-screen player
- **Seek Control**: Use the progress slider to jump to any position
- **Skip Controls**: Previous/next buttons (when multiple songs available)

### File Management

The app searches common directories:
- `/storage/emulated/0/Music`
- `/storage/emulated/0/Download`
- `/storage/emulated/0/Documents`

You can also use the file picker to select MP3 files from any location.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── song.dart            # Song data model
├── providers/
│   └── music_provider.dart  # State management
├── screens/
│   ├── music_list_screen.dart   # Main song list
│   ├── now_playing_screen.dart  # Full player UI
│   └── splash_screen.dart       # Loading screen
├── services/
│   ├── audio_player_service.dart # Audio playback logic
│   └── music_service.dart        # File discovery
├── theme/
│   └── dracula_theme.dart   # UI theme configuration
└── utils/
    └── debug_logger.dart    # Development logging
```

## Permissions

The app requires the following Android permissions:
- `READ_EXTERNAL_STORAGE`: Access music files
- `WRITE_EXTERNAL_STORAGE`: Cache and metadata
- `MANAGE_EXTERNAL_STORAGE`: Android 11+ file access
- `WAKE_LOCK`: Prevent sleep during playback
- `FOREGROUND_SERVICE`: Background audio playback

## Troubleshooting

### No Music Found
- Ensure you have MP3 files on your device
- Grant storage permissions when prompted
- Try the "Browse Files" button to manually select files
- Check that files are in supported locations

### Playback Issues
- Verify MP3 files aren't corrupted
- Restart the app if audio stops working
- Check device volume and audio settings

### Permission Issues
- Go to device Settings > Apps > Strep > Permissions
- Enable "Files and media" or "Storage" permissions
- For Android 11+, you may need to enable "All files access"

## Development

### Adding Features
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
