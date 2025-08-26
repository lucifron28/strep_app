import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/music_service.dart';

class MusicProvider extends ChangeNotifier {
  final AudioPlayerService _audioService = AudioPlayerService();
  final MusicService _musicService = MusicService();

  List<Song> _songs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AudioPlayerService get audioService => _audioService;

  Song? get currentSong => _audioService.currentSong;
  PlayerState get playerState => _audioService.playerState;
  int get currentIndex => _audioService.currentIndex;

  Future<void> initialize() async {
    await _audioService.initialize();
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

      final songs = await _musicService.loadMusicFiles();
      _songs = songs;
      
      if (songs.isNotEmpty) {
        await _audioService.setPlaylist(songs);
      } else {
        _setError('No MP3 files found. Please ensure you have MP3 files on your device.');
      }
    } catch (e) {
      _setError('Error loading music: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> playSong(Song song) async {
    try {
      await _audioService.playSong(song);
      notifyListeners();
    } catch (e) {
      _setError('Error playing song: $e');
    }
  }

  Future<void> playPause() async {
    try {
      await _audioService.playPause();
      notifyListeners();
    } catch (e) {
      _setError('Error toggling playback: $e');
    }
  }

  Future<void> skipToNext() async {
    try {
      await _audioService.skipToNext();
      notifyListeners();
    } catch (e) {
      _setError('Error skipping to next song: $e');
    }
  }

  Future<void> skipToPrevious() async {
    try {
      await _audioService.skipToPrevious();
      notifyListeners();
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
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
