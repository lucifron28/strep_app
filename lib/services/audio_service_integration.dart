import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import 'audio_handler_service.dart';

class AudioServiceIntegration {
  static final AudioServiceIntegration _instance = AudioServiceIntegration._internal();
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
          androidNotificationChannelId: 'com.example.strep_app.channel.audio',
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
      _audioHandler?.queue.add([]);
      return;
    }

    final mediaItems = songs.map((song) => songToMediaItem(song)).toList();
    await _audioHandler?.setAudioSource(mediaItems, initialIndex: initialIndex);
  }

  // Update current media item
  Future<void> updateCurrentSong(Song song) async {
    if (!_initialized || _audioHandler == null) return;

    final mediaItem = songToMediaItem(song);
    await _audioHandler?.updateMediaItem(mediaItem);
  }

  // Note: The following methods now delegate to AudioPlayerService through StrepAudioHandler
  // This ensures synchronization between the app and notification controls
  
  // Play/Pause
  Future<void> playPause() async {
    if (!_initialized || _audioHandler == null) return;
    
    if (_audioHandler!.playbackState.value.playing) {
      await _audioHandler?.pause();
    } else {
      await _audioHandler?.play();
    }
  }

  // Skip to next
  Future<void> skipToNext() async {
    if (!_initialized || _audioHandler == null) return;
    await _audioHandler?.skipToNext();
  }

  // Skip to previous
  Future<void> skipToPrevious() async {
    if (!_initialized || _audioHandler == null) return;
    await _audioHandler?.skipToPrevious();
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
}
