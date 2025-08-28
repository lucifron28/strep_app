import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/music_service.dart';
import '../services/song_metadata_service.dart';
import '../services/song_storage_service.dart';

class MusicProvider extends ChangeNotifier {
  final AudioPlayerService _audioService = AudioPlayerService();
  final MusicService _musicService = MusicService();
  final SongMetadataService _metadataService = SongMetadataService();
  final SongStorageService _storageService = SongStorageService();

  List<Song> _songs = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _disposed = false;

  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AudioPlayerService get audioService => _audioService;

  // The song currently playing in the audio service
  Song? get currentSong => _audioService.currentSong;
  PlayerState get playerState => _audioService.playerState;
  int get currentIndex => _audioService.currentIndex;

  final List<Song> _queue = [];
  int _queueIndex = 0;
  
  List<Song> get queue => List.unmodifiable(_queue);
  int get queueIndex => _queueIndex;
  // The song currently selected in the queue
  Song? get queuedSong => _queue.isNotEmpty ? _queue[_queueIndex] : null;

  Future<void> initialize() async {
    await _audioService.initialize();
    
    // Listen to player state changes and notify UI
    _playerStateSubscription = _audioService.playerStateStream.listen((_) {
      if (_disposed) return;

      // Sync queue index with audio service
      final current = _audioService.currentSong;
      final idx = _queue.indexWhere((s) => s.path == current?.path);
      if (idx != -1 && idx != _queueIndex) {
        _queueIndex = idx;
      }
      notifyListeners();
    });
    
    await loadMusic();
  }

  Future<void> loadMusic() async {
    _setLoading(true);
    _clearError();

    try {
      final hasPermission = await _musicService.requestStoragePermission();
      
      if (!hasPermission) {
        _setError('Storage permission is required to access music files');
        return;
      }

      // First try to load stored songs
      List<Song> songs = await _storageService.loadSongs();
      
      // If no stored songs, scan for new ones
      if (songs.isEmpty) {
        songs = await _musicService.loadMusicFiles();
        if (songs.isNotEmpty) {
          // Save the newly found songs
          await _storageService.saveSongs(songs);
        }
      }
      
      // Apply any saved metadata to the songs
      final songsWithMetadata = await _metadataService.applyMetadataToSongs(songs);
      _songs = songsWithMetadata;
      
      if (songs.isNotEmpty) {
        await _audioService.setPlaylist(songsWithMetadata);
      } else {
        _setError('No MP3 files found. Use the import button to add music files.');
      }
    } catch (e) {
      _setError('Error loading music: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> importMusic() async {
    try {
      final hasPermission = await _musicService.requestStoragePermission();
      
      if (!hasPermission) {
        _setError('Storage permission is required to access music files');
        return;
      }

      final newSongs = await _musicService.importMusicFiles();
      
      if (newSongs.isNotEmpty) {
        // Add new songs to storage
        await _storageService.addSongs(newSongs);
        
        // Reload the complete song list
        await loadMusic();
      }
    } catch (e) {
      _setError('Error importing music: $e');
    }
  }

  Future<void> playSong(Song song) async {
  try {
    // If song is not in queue, add it and set as current
    final idx = _queue.indexWhere((s) => s.path == song.path);
    if (idx == -1) {
      _queue.add(song);
      _queueIndex = _queue.length - 1;
      await _audioService.setPlaylist(_queue);
    } else {
      _queueIndex = idx;
    }
    await _audioService.playSong(song);
    // notifyListeners() will be called by the stream listener
  } catch (e) {
    _setError('Error playing song: $e');
  }
}

  Future<void> playPause() async {
    try {
      await _audioService.playPause();
      // notifyListeners() will be called automatically by the stream listener
    } catch (e) {
      _setError('Error toggling playback: $e');
    }
  }

  Future<void> skipToNext() async {
    try {
      await _audioService.skipToNext();
      // notifyListeners() will be called automatically by the stream listener
    } catch (e) {
      _setError('Error skipping to next song: $e');
    }
  }

  Future<void> skipToPrevious() async {
    try {
      await _audioService.skipToPrevious();
      // notifyListeners() will be called automatically by the stream listener
    } catch (e) {
      _setError('Error skipping to previous song: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioService.seek(position);
    } catch (e) {
      _setError('Error seeking: $e');
    }
  }

  Future<void> updateSongDetails(Song oldSong, Song updatedSong) async {
    try {
      // Find the song in the list and update it
      final index = _songs.indexWhere((song) => song.path == oldSong.path);
      if (index != -1) {
        _songs[index] = updatedSong;
        
        // Save the metadata for persistence
        await _metadataService.saveSongDetails(updatedSong);
        
        // If this is the currently playing song, update it in the audio service
        if (_audioService.currentSong?.path == oldSong.path) {
          await _audioService.updateCurrentSong(updatedSong);
        }
        
        notifyListeners();
      }
    } catch (e) {
      _setError('Error updating song details: $e');
    }
  }

  Future<void> updateSongThumbnail(Song song, String thumbnailPath) async {
    try {
      final updatedSong = song.copyWith(customThumbnail: thumbnailPath);
      
      final index = _songs.indexWhere((s) => s.path == song.path);
      if (index != -1) {
        _songs[index] = updatedSong;
        
        await _metadataService.saveSongDetails(updatedSong);
        
        if (_audioService.currentSong?.path == song.path) {
          await _audioService.updateCurrentSong(updatedSong);
        }
        
        notifyListeners();
      }
    } catch (e) {
      _setError('Error updating song thumbnail: $e');
    }
  }

  Future<void> deleteSong(Song songToDelete) async {
    try {
      // Find the song in the list
      final index = _songs.indexWhere((song) => song.path == songToDelete.path);
      if (index == -1) return;

      // Check if the song to delete is currently playing
      final isCurrentlyPlaying = _audioService.currentSong?.path == songToDelete.path;
      
      // Remove from the songs list
      _songs.removeAt(index);
      
      // Remove from storage
      await _storageService.removeSong(songToDelete.path);
      
      // Remove from metadata service
      await _metadataService.deleteSongMetadata(songToDelete.path);
      
      // Handle audio service updates
      if (isCurrentlyPlaying) {
        // Stop the current playback
        await _audioService.stop();
        
        // If there are still songs left, update the playlist
        if (_songs.isNotEmpty) {
          await _audioService.setPlaylist(_songs);
          // Play the next song (or first if we deleted the last one)
          final nextIndex = index < _songs.length ? index : 0;
          if (nextIndex < _songs.length) {
            await _audioService.playSong(_songs[nextIndex]);
          }
        } else {
          // No songs left, clear the playlist
          await _audioService.clearPlaylist();
        }
      } else {
        // Just update the playlist without changing playback
        await _audioService.setPlaylist(_songs);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Error deleting song: $e');
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

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
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

  void setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue
      ..clear()
      ..addAll(songs);
    _queueIndex = startIndex.clamp(0, _queue.length - 1);
    notifyListeners();

    // Update the audio service playlist and play the selected song
    // Ensures the queue is in sync with the Audio Service
    await _audioService.setPlaylist(songs);
    if (_queue.isNotEmpty) {
      await _audioService.playSong(_queue[_queueIndex]);
    }
    notifyListeners();
  }

  void addToQueue(Song song) {
    _queue.add(song);
    // Ensures the queue is in sync with the Audio Service
    _audioService.setPlaylist(_queue);
    notifyListeners();
  }

  void removeFromQueue(Song song) {
    final wasCurrent = currentSong == song;
    _queue.remove(song);
    if (wasCurrent && _queue.isNotEmpty) {
      _queueIndex = _queueIndex.clamp(0, _queue.length - 1);
    }
    // Ensures the queue is in sync with the Audio Service
    _audioService.setPlaylist(_queue);
    notifyListeners();
  }

  void playNext() {
    if (_queueIndex < _queue.length - 1) {
      _queueIndex++;
    }
    // Ensures the queue is in sync with the Audio Service
    _audioService.setPlaylist(_queue);
    notifyListeners();
  }

  void playPrevious() {
    if (_queueIndex > 0) {
      _queueIndex--;
    }
    // Ensures the queue is in sync with the Audio Service
    _audioService.setPlaylist(_queue);
    notifyListeners();
  }

  void playSongAt(int index) {
    if (index >= 0 && index < _queue.length) {
      _queueIndex = index;
    // Ensures the queue is in sync with the Audio Service
    _audioService.setPlaylist(_queue);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _playerStateSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
