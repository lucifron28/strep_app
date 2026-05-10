# Strep

Strep is a Flutter Android music player for local audio playback, file import, queue management, background playback controls, custom thumbnails, and permitted YouTube audio downloads.

## Features

- Import local audio files with Android's file picker.
- Play, pause, seek, skip, and manage a playback queue.
- Keep the mini player, now playing screen, and Android media notification in sync through `audio_service` and one `just_audio` player.
- Download audio from normal public YouTube videos supported by `youtube_explode_dart`.
- Track foreground/background download progress, cancellation, retry, and persistence.
- Edit song title, artist, album, and custom thumbnails.
- Persist the library with SharedPreferences.

## Supported Audio Formats

Imports allow:

- MP3
- M4A
- AAC
- WAV
- FLAC
- OGG
- WEBM

Actual playback support can still depend on the Android device codecs and the stream/container produced by the source.

## YouTube Download Disclaimer

Only download content you own or have permission to download. Strep does not implement DRM bypass, cookie login, age-gate bypass, region-lock bypass, anti-bot evasion, or any workaround for YouTube restrictions. Downloads are limited to normal public content accessible through `youtube_explode_dart`.

Known limitations:

- Private, members-only, purchased, age-restricted, region-blocked, live-only, or otherwise unavailable videos may fail.
- Network failures and upstream YouTube changes can interrupt downloads.
- Playlist and quality-selection workflows are not implemented yet.

## Tech Stack

- Flutter stable and Dart
- `provider` for app state
- `just_audio` for playback
- `audio_service` for Android media notification/session controls
- `youtube_explode_dart` for public YouTube metadata and streams
- `file_picker` for Storage Access Framework-style imports
- `path_provider` for app-owned download storage
- `shared_preferences` for library persistence
- `permission_handler` and `device_info_plus` for version-aware optional media scanning permissions

## Requirements

- Flutter stable SDK
- Dart SDK bundled with Flutter
- Android Studio or an Android SDK installation
- Android emulator or device

Check your local toolchain:

```sh
flutter --version
dart --version
flutter doctor
```

## Setup

```sh
git clone https://github.com/lucifron28/strep_app.git
cd strep_app
flutter pub get
```

## Running Locally

```sh
flutter run
```

Useful checks:

```sh
flutter analyze
flutter test
flutter build apk --debug
```

## Building APKs

Debug APK:

```sh
flutter build apk --debug
```

Release APKs must be signed with your own key. Do not commit keystores, passwords, APKs, AABs, or `android/key.properties`.

Create `android/key.properties` locally:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=app/upload-keystore.jks
```

Then build:

```sh
flutter build apk --release
```

Publish installable APKs through GitHub Releases or GitHub Actions artifacts, not by committing files under `build/`.

## Permissions

Strep requests only the Android permissions needed for its implemented behavior:

- `INTERNET` for YouTube metadata and downloads.
- Foreground media playback service permissions for background audio controls.
- `READ_MEDIA_AUDIO` on Android 13+ only when scanning shared audio folders.
- `READ_EXTERNAL_STORAGE` up to Android 12L only when scanning shared audio folders.

Normal file imports use the system file picker, so broad storage access and `MANAGE_EXTERNAL_STORAGE` are not required. Custom thumbnails use Android Photo Picker where available rather than broad image-library permission.

## Architecture

- `MusicProvider` owns library state, queue state, import/download integration, and persistence coordination.
- `AudioServiceIntegration` initializes `audio_service` and exposes one `StrepAudioHandler`.
- `StrepAudioHandler` owns the single `just_audio` player used for normal playback and notification controls.
- `YouTubeDownloadService` validates URLs, fetches video info, downloads to `.part` files, handles cancellation, and returns typed results.
- `DownloadManagerService` queues background downloads, throttles progress updates, supports cancellation/retry, and reports completed songs back to `MusicProvider`.
- `SongStorageService` persists the library as JSON in SharedPreferences.

SharedPreferences is sufficient for the current library size and compatibility needs. A future migration to a local database should be considered before adding playlists, full-text search, large-library indexing, or richer relational metadata.

## Troubleshooting

- If imports show no files, confirm the selected files use one of the supported extensions.
- If folder scanning is denied, enable audio/media permission in Android app settings.
- If a song no longer plays, the underlying file may have been moved or deleted.
- If YouTube info or downloads fail, try a normal public video URL and verify network access.
- If release signing fails, check `android/key.properties` paths and passwords.

## Roadmap

- Local database migration for larger libraries.
- Folder browser and explicit media-store scanning UI.
- Playlists and favorites.
- Lyrics and richer metadata extraction.
- Optional audio effects and crossfade.
- Better artwork caching.

## Contributing

Bug reports should include Android version, device/emulator, steps to reproduce, expected behavior, actual behavior, and any relevant `flutter analyze` or log output. Pull requests should run:

```sh
flutter format .
flutter analyze
flutter test
flutter build apk --debug
```

## License

MIT License. See [LICENSE](LICENSE).
