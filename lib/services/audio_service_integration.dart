import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import 'audio_handler_service.dart';

class AudioServiceIntegration {
  static final AudioServiceIntegration _instance =
      AudioServiceIntegration._internal();
  factory AudioServiceIntegration() => _instance;
  AudioServiceIntegration._internal();

  StrepAudioHandler? _audioHandler;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize the audio handler
      _audioHandler = await AudioService.init(
        builder: () => StrepAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.lucifron.strep.channel.audio',
          androidNotificationChannelName: 'Strep Audio playback',
          androidNotificationChannelDescription: 'Controls for audio playback',
          androidNotificationOngoing: false,
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: true,
        ),
      );

      _initialized = true;
    } catch (e) {
      // Use a proper logger instead of print in production
      debugPrint('Failed to initialize AudioService: $e');
      rethrow;
    }
  }

  // Convert Song to MediaItem
  MediaItem songToMediaItem(Song song) {
    return StrepAudioHandler.createMediaItem(
      id: song.path,
      title: song.title.isEmpty ? 'Unknown Title' : song.title,
      artist: song.artist.isEmpty ? 'Unknown Artist' : song.artist,
      album: song.album.isEmpty ? 'Unknown Album' : song.album,
      duration: song.duration,
      // For now, we'll use null for artUri, but this could be enhanced later
      artUri: null,
    );
  }

  // Update the audio service with current playlist
  Future<void> updatePlaylist(List<Song> songs, {int initialIndex = 0}) async {
    if (!_initialized || _audioHandler == null) {
      await initialize();
    }

    if (songs.isEmpty) {
      if (_audioHandler is StrepAudioHandler) {
        await (_audioHandler as StrepAudioHandler).clearPlaylist();
      } else {
        _audioHandler?.queue.add([]);
      }
      return;
    }

    // Use the new method that handles songs directly
    if (_audioHandler is StrepAudioHandler) {
      await (_audioHandler as StrepAudioHandler).setAudioSourceFromSongs(
        songs,
        initialIndex: initialIndex,
      );
    }
  }

  // Update current media item
  Future<void> updateCurrentSong(Song song) async {
    if (!_initialized || _audioHandler == null) return;

    final mediaItem = songToMediaItem(song);
    await _audioHandler?.updateMediaItem(mediaItem);

    if (_audioHandler is StrepAudioHandler) {
      await (_audioHandler as StrepAudioHandler).replaceCurrentSong(song);
    }
  }

  // Get the underlying audio player for direct access (for UI components)
  AudioPlayer? get audioPlayer {
    if (_audioHandler is StrepAudioHandler) {
      return (_audioHandler as StrepAudioHandler).player;
    }
    return null;
  }

  // Get current song from handler
  Song? get currentSong {
    if (_audioHandler is StrepAudioHandler) {
      return (_audioHandler as StrepAudioHandler).currentSong;
    }
    return null;
  }

  // Get current index from handler
  int get currentIndex {
    if (_audioHandler is StrepAudioHandler) {
      return (_audioHandler as StrepAudioHandler).currentIndex;
    }
    return 0;
  }

  // Get playlist from handler
  List<Song> get playlist {
    if (_audioHandler is StrepAudioHandler) {
      return (_audioHandler as StrepAudioHandler).playlist;
    }
    return [];
  }

  // Play/Pause
  Future<void> playPause() async {
    if (!_initialized || _audioHandler == null) return;

    if (_audioHandler!.playbackState.value.playing) {
      await _audioHandler?.pause();
    } else {
      await _audioHandler?.play();
    }

    if (_audioHandler is StrepAudioHandler) {
      (_audioHandler as StrepAudioHandler).forceSync();
    }
  }

  Future<void> play() async {
    if (!_initialized || _audioHandler == null) return;
    await _audioHandler?.play();

    if (_audioHandler is StrepAudioHandler) {
      (_audioHandler as StrepAudioHandler).forceSync();
    }
  }

  // Skip to next
  Future<void> skipToNext() async {
    if (!_initialized || _audioHandler == null) return;
    await _audioHandler?.skipToNext();

    if (_audioHandler is StrepAudioHandler) {
      (_audioHandler as StrepAudioHandler).forceSync();
    }
  }

  // Skip to previous
  Future<void> skipToPrevious() async {
    if (!_initialized || _audioHandler == null) return;
    await _audioHandler?.skipToPrevious();

    if (_audioHandler is StrepAudioHandler) {
      (_audioHandler as StrepAudioHandler).forceSync();
    }
  }

  Future<void> skipToQueueItem(int index) async {
    if (!_initialized || _audioHandler == null) return;
    await _audioHandler?.skipToQueueItem(index);

    if (_audioHandler is StrepAudioHandler) {
      (_audioHandler as StrepAudioHandler).forceSync();
    }
  }

  // Seek
  Future<void> seek(Duration position) async {
    if (!_initialized || _audioHandler == null) return;
    await _audioHandler?.seek(position);
  }

  // Stop
  Future<void> stop() async {
    if (!_initialized || _audioHandler == null) return;
    await _audioHandler?.stop();
  }

  void dispose() {
    _audioHandler = null;
    _initialized = false;
  }

  bool get isPlaying => _audioHandler?.playbackState.value.playing ?? false;

  String? get currentSongTitle => _audioHandler?.mediaItem.value?.title;
}
