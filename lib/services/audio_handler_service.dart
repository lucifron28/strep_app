import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_player_service.dart' as audio_service;

class StrepAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final audio_service.AudioPlayerService _audioPlayerService = audio_service.AudioPlayerService();
  
  // Use the same AudioPlayer instance from AudioPlayerService
  AudioPlayer get _player => _audioPlayerService.audioPlayer;

  StrepAudioHandler() {
    _initializeListeners();
  }

  void _initializeListeners() {
    // Listen to player state changes from the AudioPlayerService
    _audioPlayerService.playerStateStream.listen((playerState) {
      final isPlaying = playerState == audio_service.PlayerState.playing;
      final isLoading = playerState == audio_service.PlayerState.loading;
      
      playbackState.add(playbackState.value.copyWith(
        playing: isPlaying,
        processingState: isLoading 
          ? AudioProcessingState.loading 
          : AudioProcessingState.ready,
        controls: [
          MediaControl.skipToPrevious,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
      ));
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Update media item when current song changes
    final currentSong = _audioPlayerService.currentSong;
    if (currentSong != null) {
      final mediaItem = createMediaItem(
        id: currentSong.path,
        title: currentSong.title,
        artist: currentSong.artist,
        album: currentSong.album,
        duration: currentSong.duration,
      );
      this.mediaItem.add(mediaItem);
    }
  }

  void _updateCurrentIndexFromService() {
    final currentSong = _audioPlayerService.currentSong;
    if (currentSong != null) {
      final mediaItem = createMediaItem(
        id: currentSong.path,
        title: currentSong.title,
        artist: currentSong.artist,
        album: currentSong.album,
        duration: currentSong.duration,
      );
      this.mediaItem.add(mediaItem);
    }
  }

    @override
  Future<void> play() async {
    await _audioPlayerService.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayerService.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayerService.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayerService.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    await _audioPlayerService.skipToNext();
    _updateCurrentIndexFromService();
  }

  @override
  Future<void> skipToPrevious() async {
    await _audioPlayerService.skipToPrevious();
    _updateCurrentIndexFromService();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < queue.value.length) {
      await _player.seek(Duration.zero, index: index);
      final currentSong = _audioPlayerService.currentSong;
      if (currentSong != null && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    }
  }

  // Helper method to create MediaItem from Song
  static MediaItem createMediaItem({
    required String id,
    required String title,
    required String artist,
    required String album,
    Duration? duration,
    Uri? artUri,
  }) {
    return MediaItem(
      id: id,
      album: album.isEmpty ? 'Unknown Album' : album,
      title: title.isEmpty ? 'Unknown Title' : title,
      artist: artist.isEmpty ? 'Unknown Artist' : artist,
      duration: duration,
      artUri: artUri,
      playable: true,
      extras: {
        'source': 'local',
      },
    );
  }

  // To set the queue and media item:
  Future<void> setAudioSource(List<MediaItem> items, {int initialIndex = 0}) async {
    if (items.isEmpty) return;
    
    // Clear and set the queue
    queue.add(items);
    
    // Set current media item
    mediaItem.add(items[initialIndex]);
    
    // Use the AudioPlayerService to set the playlist instead of doing it directly
    // This ensures synchronization between the notification and the app
    // The actual audio sources will be set through the AudioPlayerService
  }

  // Method to update current song info
  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
  }

  @override
  Future<void> onTaskRemoved() async {
    // Handle when user swipes away the app from recents
    await stop();
  }

  @override
  Future<void> onNotificationDeleted() async {
    // Handle when user dismisses the notification
    await stop();
  }
}