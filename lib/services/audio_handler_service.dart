import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class StrepAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  // Create our own AudioPlayer instance that we fully control
  final AudioPlayer _player = AudioPlayer();

  List<Song> _playlist = [];
  int _currentIndex = 0;
  Song? _currentSong;

  StrepAudioHandler() {
    _initializeListeners();
  }

  void _initializeListeners() {
    // Listen to player state changes directly from just_audio
    _player.playerStateStream.listen((state) {
      _updatePlaybackState();
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      playbackState.add(
        playbackState.value.copyWith(
          bufferedPosition: duration ?? Duration.zero,
        ),
      );
    });

    // Listen to sequence state changes for current song updates
    _player.sequenceStateStream.listen((sequenceState) {
      final newIndex = sequenceState.currentIndex;
      if (newIndex == null || _playlist.isEmpty) {
        return;
      }

      if (newIndex < _playlist.length) {
        _currentIndex = newIndex;
        _currentSong = _playlist[newIndex];
        _updateCurrentMediaItem();
        _updatePlaybackState();
      }
    });
  }

  void _updatePlaybackState() {
    final state = _player.playerState;
    final isPlaying = state.playing;
    final isLoading =
        state.processingState == ProcessingState.loading ||
        state.processingState == ProcessingState.buffering;
    final isStopped = state.processingState == ProcessingState.idle;

    playbackState.add(
      playbackState.value.copyWith(
        playing: isPlaying,
        processingState: isStopped
            ? AudioProcessingState.idle
            : isLoading
            ? AudioProcessingState.loading
            : AudioProcessingState.ready,
        controls: [
          MediaControl.skipToPrevious,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        queueIndex: _currentIndex,
      ),
    );
  }

  void _updateCurrentMediaItem() {
    if (_currentSong != null) {
      final mediaItem = createMediaItem(
        id: _currentSong!.path,
        title: _currentSong!.title,
        artist: _currentSong!.artist,
        album: _currentSong!.album,
        duration: _currentSong!.duration,
      );
      this.mediaItem.add(mediaItem);
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _updatePlaybackState();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < queue.value.length && index < _playlist.length) {
      await _player.seek(Duration.zero, index: index);
      _currentIndex = index;
      _currentSong = _playlist[index];
      _updateCurrentMediaItem();
      _updatePlaybackState();
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
      extras: {'source': 'local'},
    );
  }

  // Set the audio sources from songs
  Future<void> setAudioSourceFromSongs(
    List<Song> songs, {
    int initialIndex = 0,
  }) async {
    if (songs.isEmpty) {
      await clearPlaylist();
      return;
    }

    _playlist = songs;
    _currentIndex = initialIndex.clamp(0, songs.length - 1).toInt();
    _currentSong = songs[_currentIndex];

    // Convert songs to MediaItems for the queue
    final mediaItems = songs
        .map(
          (song) => createMediaItem(
            id: song.path,
            title: song.title,
            artist: song.artist,
            album: song.album,
            duration: song.duration,
          ),
        )
        .toList();

    // Set the queue
    queue.add(mediaItems);

    // Set current media item
    mediaItem.add(mediaItems[_currentIndex]);

    // Set audio sources for just_audio
    final audioSources = songs.map((song) {
      final uri = song.path.startsWith('file://')
          ? Uri.parse(song.path)
          : Uri.file(song.path);
      return AudioSource.uri(uri);
    }).toList();

    await _player.setAudioSources(
      audioSources,
      initialIndex: _currentIndex,
      initialPosition: Duration.zero,
    );
    _updatePlaybackState();
  }

  // Legacy method for MediaItems (still used by integration layer)
  Future<void> setAudioSource(
    List<MediaItem> items, {
    int initialIndex = 0,
  }) async {
    if (items.isEmpty) {
      await clearPlaylist();
      return;
    }

    // Clear and set the queue
    queue.add(items);

    // Set current media item
    if (initialIndex < items.length) {
      mediaItem.add(items[initialIndex]);
    }

    // Update playback state to ensure notification shows correct controls
    _updatePlaybackState();
  }

  // Method to update current media item
  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
  }

  Future<void> replaceCurrentSong(Song song) async {
    final index = _playlist.indexWhere((item) => item.path == song.path);
    if (index == -1) return;

    _playlist[index] = song;
    if (_currentSong?.path == song.path) {
      _currentSong = song;
      _updateCurrentMediaItem();
    }

    queue.add(
      _playlist
          .map(
            (item) => createMediaItem(
              id: item.path,
              title: item.title,
              artist: item.artist,
              album: item.album,
              duration: item.duration,
            ),
          )
          .toList(),
    );
  }

  Future<void> clearPlaylist() async {
    _playlist = [];
    _currentIndex = 0;
    _currentSong = null;
    queue.add(const []);
    mediaItem.add(null);
    await _player.stop();
    await _player.clearAudioSources();
    _updatePlaybackState();
  }

  // Public methods for synchronization
  void updateCurrentSong() {
    _updateCurrentMediaItem();
  }

  void forceSync() {
    _updateCurrentMediaItem();
    _updatePlaybackState();
  }

  // Expose player properties for external access
  AudioPlayer get player => _player;
  Song? get currentSong => _currentSong;
  List<Song> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  @override
  Future<void> onNotificationDeleted() async {
    await stop();
  }

  void dispose() {
    _player.dispose();
  }
}
