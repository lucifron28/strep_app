
# APK Beta Release

[Download the latest beta APK here](build/app/outputs/flutter-apk/Strep.apk)

# Strep Music Player

**Strep** is a modern, open-source music player for Android built with Flutter. This project is **still under development**. An APK release will be available when the app is feature-complete.


## Overview

Strep is a modern, open-source music player for Android built with Flutter. It supports local audio playback, YouTube audio downloads, queue management, and a beautiful Dracula-inspired UI. The app is designed for speed, reliability, and customization.

## Features

- **Local Audio Playback:** Play music files stored on your device (supports MP3, M4A, WEBM, and other common formats).
- **YouTube Audio Download:** Download audio from YouTube links directly in the app using `youtube_explode_dart`.
- **Music Library:** Import, browse, and manage your songs with album, artist, and all-songs views.
- **Queue & Now Playing:** Spotify-style queue management and a full-featured now playing screen.
- **Mini Player:** Persistent mini player for quick controls and navigation.
- **Edit & Delete:** Edit song metadata and remove songs from your library.
- **Custom Thumbnails:** Set custom artwork for your songs.
- **Persistent Storage:** Your library and playback state are saved between sessions.
- **File Picker:** Import music from any location on your device.


## Codebase Structure

```
lib/
   main.dart                  # App entry point, theme, and navigation
   models/
      song.dart                # Song model and metadata
   providers/
      music_provider.dart      # State management for music, queue, and playback
   services/
      audio_player_service.dart    # Audio playback and queue logic (just_audio)
      yt_service_explode.dart      # YouTube audio download and info
      music_service.dart           # File system and permission helpers
      song_metadata_service.dart   # Metadata editing and persistence
      song_storage_service.dart    # Persistent storage for song list
      image_service.dart           # Album art and thumbnail helpers
   screens/
      music_list_screen.dart   # Main UI: song list, albums, artists, mini player
      now_playing_screen.dart  # Full now playing screen (not shown above)
   widgets/
      youtube_download_dialog.dart # Dialog for YouTube downloads
      song_options_bottom_sheet.dart # Edit/delete song options
      song_thumbnail.dart      # Song artwork widget
      vinyl_disk.dart          # SVG vinyl disk backgrounds
      strep_icon.dart          # App icon widget
      queue_modal.dart         # Queue management modal
   theme/
      dracula_theme.dart       # Dracula color palette and theme
   utils/
      debug_logger.dart        # Debug logging utility
test/
   widget_test.dart           # Widget tests
```

## Key Components

- **main.dart**: App entry, theme, and navigation. Initializes the music provider and shows the splash screen or main UI.
- **MusicProvider**: Central state manager for songs, queue, and playback. Handles loading, importing, editing, and deleting songs, as well as YouTube downloads.
- **AudioPlayerService**: Handles all playback logic, queue management, and persistent playback state using just_audio.
- **YouTubeDownloadService**: Downloads audio from YouTube links and creates Song objects for the library.
- **UI Screens**: Main music list, albums, artists, and now playing screens. Includes a persistent mini player and queue modal.
- **Widgets**: Modular UI components for song tiles, thumbnails, dialogs, and options.
- **Theme**: Dracula-inspired dark theme with custom gradients and colors.

## Usage

- MP3
- M4A
- WEBM (YouTube audio)
- Most common audio formats supported by your device

## Getting Started

### Prerequisites

- Flutter SDK (3.10.0 or higher recommended)
- Android Studio or VS Code with Flutter extensions
- Android device or emulator (API 21+)

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/lucifron28/strep_app.git
   cd strep_app
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Run the app:**
   ```sh
   flutter run
   ```

## Usage

- **Import Music:** Use the add (+) button to import audio files.
- **Download from YouTube:** Paste a YouTube link to download and add audio to your library.
- **Browse Library:** Switch between All Songs, Albums, and Artists tabs.
- **Play Music:** Tap any song to start playback. Use the mini player or now playing screen for controls.
- **Manage Queue:** Tap the queue button in the now playing screen to view and manage your up-next list.


## How to Use

- **Import Music**: Tap the add (+) button to import audio files from your device.
- **Download from YouTube**: Tap the YouTube icon, paste a link, and download audio directly into your library.
- **Browse Library**: Switch between All Songs, Albums, and Artists tabs.
- **Play Music**: Tap a song to play. Tapping the currently playing song toggles pause/play. Use the mini player or now playing screen for controls.
- **Edit/Delete**: Long-press or use the options menu on a song to edit metadata or remove it from your library.
- **Queue Management**: Use the queue modal to view and reorder upcoming songs.

## Permissions

- Storage/media access (to read and write music files)
- Internet (for YouTube downloads)
- Foreground service (for background playback)


## Development & Contribution

- This project is actively developed. Features and UI may change.
- To contribute, open an issue or pull request on GitHub.


## Future Improvements

- Notification player controls and lock screen controls
- Android Auto and Wear OS support
- Lyrics display and lyrics search
- Smart playlists and favorites
- Folder-based browsing
- Gapless playback and crossfade
- Audio effects (equalizer, bass boost)
- More file format support (FLAC, OGG, etc.)
- Improved queue management (drag-and-drop, multi-select)
- Custom themes and accent colors
- Backup and restore library
- In-app update notifications
- Better error handling and user feedback
- Performance optimizations for large libraries
- More robust YouTube download options (quality selection, playlists)

---

- This project is **actively being developed**.
- Features and UI are subject to change.
- APK will be released when the app is ready for public use.

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

MIT License
