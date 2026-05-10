import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import '../services/audio_service_integration.dart';
import '../services/download_manager_service.dart';
import '../services/music_service.dart';
import '../services/song_metadata_service.dart';
import '../services/song_storage_service.dart';
import '../services/yt_service_explode.dart';

class MusicProvider extends ChangeNotifier {
  MusicProvider({
    AudioServiceIntegration? audioServiceIntegration,
    DownloadManagerService? downloadManager,
    MusicService? musicService,
    SongMetadataService? metadataService,
    SongStorageService? storageService,
    YouTubeDownloadService? youtubeService,
    List<Song>? initialSongs,
    bool listenToDownloads = true,
  }) : _audioServiceIntegration =
           audioServiceIntegration ?? AudioServiceIntegration(),
       _downloadManager = downloadManager ?? DownloadManagerService(),
       _musicService = musicService ?? MusicService(),
       _metadataService = metadataService ?? SongMetadataService(),
       _storageService = storageService ?? SongStorageService(),
       _youtubeService = youtubeService ?? YouTubeDownloadService(),
       _songs = List<Song>.from(initialSongs ?? const []) {
    if (listenToDownloads) {
      _downloadManager.addListener(_handleDownloadManagerChanged);
    }
  }

  final AudioServiceIntegration _audioServiceIntegration;
  final DownloadManagerService _downloadManager;
  final MusicService _musicService;
  final SongMetadataService _metadataService;
  final SongStorageService _storageService;
  final YouTubeDownloadService _youtubeService;

  List<Song> _songs;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _disposed = false;
  bool _processingCompletedDownloads = false;
  final Set<String> _processedDownloadIds = <String>{};

  List<Song> get songs => List.unmodifiable(_songs);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DownloadManagerService get downloadManager => _downloadManager;

  Song? get currentSong => _audioServiceIntegration.currentSong;
  int get currentIndex => _audioServiceIntegration.currentIndex;
  List<Song> get playlist => _audioServiceIntegration.playlist;

  PlayerState get playerState =>
      _audioServiceIntegration.audioPlayer?.playerState ??
      PlayerState(false, ProcessingState.idle);
  Duration get currentPosition =>
      _audioServiceIntegration.audioPlayer?.position ?? Duration.zero;
  Duration? get totalDuration => _audioServiceIntegration.audioPlayer?.duration;
  Stream<Duration> get positionStream =>
      _audioServiceIntegration.audioPlayer?.positionStream ??
      Stream.value(Duration.zero);

  final List<Song> _queue = [];
  int _queueIndex = 0;

  List<Song> get queue => List.unmodifiable(_queue);
  int get queueIndex => _queueIndex;
  Song? get queuedSong => _queue.isNotEmpty ? _queue[_queueIndex] : null;

  Future<void> initialize() async {
    await _audioServiceIntegration.initialize();

    final audioPlayer = _audioServiceIntegration.audioPlayer;
    if (audioPlayer != null) {
      _playerStateSubscription = audioPlayer.playerStateStream.listen((_) {
        if (_disposed) return;
        _syncQueueIndexWithCurrentSong();
        notifyListeners();
      });
    }

    await loadMusic();
  }

  Future<void> loadMusic() async {
    _setLoading(true);
    _clearError(notify: false);

    try {
      final storedSongs = await _storageService.loadSongs();
      _songs = await _metadataService.applyMetadataToSongs(storedSongs);
      _queue
        ..clear()
        ..addAll(_queue.where(_songs.contains));
      _queueIndex = _queue.isEmpty
          ? 0
          : _queueIndex.clamp(0, _queue.length - 1).toInt();
    } catch (e) {
      _setError('Error loading music: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<int> importMusic() async {
    try {
      final newSongs = await _musicService.importMusicFiles();

      if (newSongs.isEmpty) {
        _setError(
          'No supported audio files were selected. Supported formats: ${MusicService.supportedExtensions.join(', ').toUpperCase()}.',
        );
        return 0;
      }

      final existingKeys = _songs.map((song) => song.path).toSet()
        ..addAll(_songs.map((song) => song.id));
      final songsToAdd = newSongs
          .where(
            (song) =>
                !existingKeys.contains(song.path) &&
                !existingKeys.contains(song.id),
          )
          .toList();

      if (songsToAdd.isEmpty) {
        _setError('Those songs are already in your library.');
        return 0;
      }

      await _storageService.addSongs(songsToAdd);
      await loadMusic();
      _clearError();
      return songsToAdd.length;
    } catch (e) {
      _setError('Error importing music: $e');
      return 0;
    }
  }

  Future<void> playSong(Song song) async {
    try {
      if (!await _ensureSongFileExists(song)) return;

      final songIndex = _songs.indexWhere((item) => item.path == song.path);
      final songsForQueue = songIndex == -1
          ? <Song>[song]
          : <Song>[
              ..._songs.sublist(songIndex),
              ..._songs.sublist(0, songIndex),
            ];

      _queue
        ..clear()
        ..addAll(songsForQueue);
      _queueIndex = 0;

      await _audioServiceIntegration.updatePlaylist(_queue, initialIndex: 0);
      await _audioServiceIntegration.updateCurrentSong(song);
      await _audioServiceIntegration.play();
      notifyListeners();
    } catch (e) {
      _setError('Could not play "${song.title}": $e');
    }
  }

  Future<void> playPause() async {
    try {
      await _audioServiceIntegration.playPause();
      notifyListeners();
    } catch (e) {
      _setError('Error toggling play/pause: $e');
    }
  }

  Future<void> skipToNext() async {
    try {
      if (_queue.isEmpty) return;
      await _audioServiceIntegration.skipToNext();
      _syncQueueIndexWithCurrentSong();
      notifyListeners();
    } catch (e) {
      _setError('Error skipping to next: $e');
    }
  }

  Future<void> skipToPrevious() async {
    try {
      if (_queue.isEmpty) return;
      await _audioServiceIntegration.skipToPrevious();
      _syncQueueIndexWithCurrentSong();
      notifyListeners();
    } catch (e) {
      _setError('Error skipping to previous: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioServiceIntegration.seek(position);
    } catch (e) {
      _setError('Error seeking: $e');
    }
  }

  Future<void> syncNotificationState() async {
    final song = currentSong;
    if (song != null) {
      await _audioServiceIntegration.updateCurrentSong(song);
    }
  }

  Future<void> updateSongDetails(Song oldSong, Song updatedSong) async {
    try {
      final index = _songs.indexWhere((song) => song.path == oldSong.path);
      if (index == -1) return;

      _songs[index] = updatedSong;
      await _storageService.saveSongs(_songs);
      await _metadataService.saveSongDetails(updatedSong);

      final queueIndex = _queue.indexWhere((song) => song.path == oldSong.path);
      if (queueIndex != -1) {
        _queue[queueIndex] = updatedSong;
      }

      if (currentSong?.path == oldSong.path) {
        await _audioServiceIntegration.updateCurrentSong(updatedSong);
      }

      notifyListeners();
    } catch (e) {
      _setError('Error updating song details: $e');
    }
  }

  Future<void> updateSongThumbnail(Song song, String thumbnailPath) async {
    try {
      final updatedSong = song.copyWith(customThumbnail: thumbnailPath);
      await updateSongDetails(song, updatedSong);
    } catch (e) {
      _setError('Error updating song thumbnail: $e');
    }
  }

  Future<void> deleteSong(Song songToDelete) async {
    try {
      final index = _songs.indexWhere((song) => song.path == songToDelete.path);
      if (index == -1) return;

      final wasCurrent = currentSong?.path == songToDelete.path;
      _songs.removeAt(index);

      final removedQueueIndex = _queue.indexWhere(
        (song) => song.path == songToDelete.path,
      );
      if (removedQueueIndex != -1) {
        _queue.removeAt(removedQueueIndex);
        if (_queueIndex >= removedQueueIndex && _queueIndex > 0) {
          _queueIndex--;
        }
      }
      _queueIndex = _queue.isEmpty
          ? 0
          : _queueIndex.clamp(0, _queue.length - 1).toInt();

      await _storageService.removeSong(songToDelete.path);
      await _metadataService.deleteSongMetadata(songToDelete.path);

      if (_queue.isEmpty) {
        await _audioServiceIntegration.updatePlaylist([]);
      } else {
        await _audioServiceIntegration.updatePlaylist(
          _queue,
          initialIndex: _queueIndex,
        );
        if (wasCurrent) {
          await _audioServiceIntegration.play();
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Error deleting song: $e');
    }
  }

  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue
      ..clear()
      ..addAll(songs);

    if (_queue.isEmpty) {
      _queueIndex = 0;
      await _audioServiceIntegration.updatePlaylist([]);
      notifyListeners();
      return;
    }

    _queueIndex = startIndex.clamp(0, _queue.length - 1).toInt();
    await _audioServiceIntegration.updatePlaylist(
      _queue,
      initialIndex: _queueIndex,
    );
    notifyListeners();
  }

  Future<void> addToQueue(Song song) async {
    _queue.add(song);
    await _audioServiceIntegration.updatePlaylist(
      _queue,
      initialIndex: _queueIndex,
    );
    notifyListeners();
  }

  Future<void> removeFromQueue(Song song) async {
    final wasCurrent = currentSong == song;
    final index = _queue.indexWhere((item) => item.path == song.path);
    if (index == -1) return;

    _queue.removeAt(index);
    _queueIndex = _queue.isEmpty
        ? 0
        : _queueIndex.clamp(0, _queue.length - 1).toInt();

    if (_queue.isEmpty) {
      await _audioServiceIntegration.updatePlaylist([]);
    } else {
      await _audioServiceIntegration.updatePlaylist(
        _queue,
        initialIndex: _queueIndex,
      );
      if (wasCurrent) {
        await _audioServiceIntegration.play();
      }
    }

    notifyListeners();
  }

  Future<void> playNext() async {
    if (_queueIndex < _queue.length - 1) {
      await playSongAt(_queueIndex + 1);
    }
  }

  Future<void> playPrevious() async {
    if (_queueIndex > 0) {
      await playSongAt(_queueIndex - 1);
    }
  }

  Future<void> playSongAt(int index) async {
    if (index < 0 || index >= _queue.length) return;

    try {
      final song = _queue[index];
      if (!await _ensureSongFileExists(song)) return;

      _queueIndex = index;
      await _audioServiceIntegration.skipToQueueItem(index);
      await _audioServiceIntegration.updateCurrentSong(song);
      await _audioServiceIntegration.play();
      notifyListeners();
    } catch (e) {
      _setError('Could not play queued song: $e');
    }
  }

  Future<void> addYouTubeSong(Song song) async {
    try {
      await _addDownloadedSongToLibrary(song);
    } catch (e) {
      _setError('Failed to add YouTube song: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      _songs.clear();
      _queue.clear();
      _queueIndex = 0;

      await _audioServiceIntegration.updatePlaylist([]);
      await _storageService.clearSongs();
      await _metadataService.clearAllMetadata();

      notifyListeners();
    } catch (e) {
      _setError('Failed to clear all data: $e');
    }
  }

  Future<bool> _addDownloadedSongToLibrary(
    Song song, {
    bool notify = true,
  }) async {
    final existsInMemory = _songs.any(
      (existing) => existing.path == song.path || existing.id == song.id,
    );

    if (existsInMemory) return false;

    _songs.add(song);
    final addedToStorage = await _storageService.addSong(song);
    if (!addedToStorage) {
      _songs.removeWhere(
        (existing) => existing.path == song.path || existing.id == song.id,
      );
      return false;
    }

    if (notify) notifyListeners();
    return true;
  }

  void _handleDownloadManagerChanged() {
    if (_disposed || _processingCompletedDownloads) return;

    final completed = _downloadManager.completedDownloads
        .where((download) => !_processedDownloadIds.contains(download.id))
        .toList();
    if (completed.isEmpty) return;

    _processingCompletedDownloads = true;
    unawaited(_persistCompletedDownloads(completed));
  }

  Future<void> _persistCompletedDownloads(List<DownloadItem> downloads) async {
    try {
      for (final download in downloads) {
        if (_disposed) return;

        _processedDownloadIds.add(download.id);
        final song = download.completedSong;
        if (song != null) {
          await _addDownloadedSongToLibrary(song, notify: false);
        }
      }

      for (final download in downloads) {
        _downloadManager.removeDownload(download.id);
      }

      notifyListeners();
    } finally {
      _processingCompletedDownloads = false;
      if (!_disposed) {
        _handleDownloadManagerChanged();
      }
    }
  }

  Future<bool> _ensureSongFileExists(Song song) async {
    final path = song.path;
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('content://')) {
      return true;
    }

    final exists = await File(path).exists();
    if (exists) return true;

    _setError(
      'The audio file for "${song.title}" could not be found. It may have been moved or deleted.',
    );
    return false;
  }

  void _syncQueueIndexWithCurrentSong() {
    final song = currentSong;
    if (song == null) return;

    final index = _queue.indexWhere((item) => item.path == song.path);
    if (index != -1) {
      _queueIndex = index;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError({bool notify = true}) {
    _errorMessage = null;
    if (notify) notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _downloadManager.removeListener(_handleDownloadManagerChanged);
    _playerStateSubscription?.cancel();
    _youtubeService.dispose();
    super.dispose();
  }
}
