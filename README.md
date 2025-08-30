# Strep Music Player

**Strep** is a modern, open-source music player for Android built with Flutter. This project is **still under development**. An APK release will be available when the app is feature-complete.

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

## Supported File Types

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

## Permissions

- Storage/media access (to read and write music files)
- Internet (for YouTube downloads)
- Foreground service (for background playback)

## Development Status

- This project is **actively being developed**.
- Features and UI are subject to change.
- APK will be released when the app is ready for public use.

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

MIT License
