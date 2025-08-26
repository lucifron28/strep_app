import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

enum PlayerState { stopped, playing, paused, loading }

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Song? _currentSong;
  List<Song> _playlist = [];
  int _currentIndex = 0;
  PlayerState _playerState = PlayerState.stopped;

  AudioPlayer get audioPlayer => _audioPlayer;
  Song? get currentSong => _currentSong;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  PlayerState get playerState => _playerState;
  
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream.map((state) {
    switch (state.processingState) {
      case ProcessingState.idle:
        return PlayerState.stopped;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return PlayerState.loading;
      case ProcessingState.ready:
        return state.playing ? PlayerState.playing : PlayerState.paused;
      case ProcessingState.completed:
        return PlayerState.stopped;
    }
  });

  Future<void> initialize() async {
    await _loadLastPlayedSong();
    
    await _audioPlayer.setAudioSource(
      ConcatenatingAudioSource(children: []),
    );

    // Listen to player state changes and update internal state
    _audioPlayer.playerStateStream.listen((state) {
      // Update internal player state based on actual player state
      switch (state.processingState) {
        case ProcessingState.idle:
          _playerState = PlayerState.stopped;
          break;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          _playerState = PlayerState.loading;
          break;
        case ProcessingState.ready:
          _playerState = state.playing ? PlayerState.playing : PlayerState.paused;
          break;
        case ProcessingState.completed:
          _playerState = PlayerState.stopped;
          _onSongCompleted();
          break;
      }
    });
  }

  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _playlist = songs;
    _currentIndex = initialIndex;
    
    if (songs.isNotEmpty) {
      final audioSources = songs.map((song) => 
        AudioSource.file(song.path)).toList();
      
      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: initialIndex,
      );
      
      _currentSong = songs[initialIndex];
      await _saveCurrentSong();
    }
  }

  Future<void> play() async {
    if (_currentSong != null) {
      await _audioPlayer.play();
      // State will be updated automatically by the stream listener
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    // State will be updated automatically by the stream listener
    await _saveCurrentPosition();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    // State will be updated automatically by the stream listener
    await _saveCurrentPosition();
  }

  Future<void> playPause() async {
    if (_audioPlayer.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> skipToNext() async {
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      await _audioPlayer.seekToNext();
      _currentSong = _playlist[_currentIndex];
      await _saveCurrentSong();
    }
  }

  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await _audioPlayer.seekToPrevious();
      _currentSong = _playlist[_currentIndex];
      await _saveCurrentSong();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    await _saveCurrentPosition();
  }

  Future<void> playSong(Song song) async {
    final index = _playlist.indexOf(song);
    if (index != -1) {
      _currentIndex = index;
      _currentSong = song;
      await _audioPlayer.seek(Duration.zero, index: index);
      await play();
      await _saveCurrentSong();
    }
  }

  Future<void> updateCurrentSong(Song updatedSong) async {
    if (_currentSong != null && _currentSong!.path == updatedSong.path) {
      _currentSong = updatedSong;
      
      // Update the song in the playlist as well
      final index = _playlist.indexWhere((song) => song.path == updatedSong.path);
      if (index != -1) {
        _playlist[index] = updatedSong;
      }
      
      await _saveCurrentSong();
    }
  }

  Future<void> clearPlaylist() async {
    _playlist.clear();
    _currentSong = null;
    _currentIndex = 0;
    await _audioPlayer.stop();
    await _audioPlayer.setAudioSource(
      ConcatenatingAudioSource(children: []),
    );
    // Clear saved preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_played_song_path');
    await prefs.remove('last_played_index');
    await prefs.remove('last_played_position');
  }

  void _onSongCompleted() {
    // Auto-play next song
    if (_currentIndex < _playlist.length - 1) {
      skipToNext();
    }
    // If this was the last song, _playerState will be set to stopped by the stream listener
  }

  Future<void> _saveCurrentSong() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentSong != null) {
      await prefs.setString('last_played_song_path', _currentSong!.path);
      await prefs.setInt('last_played_index', _currentIndex);
    }
  }

  Future<void> _saveCurrentPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final position = _audioPlayer.position;
    await prefs.setInt('last_played_position', position.inMilliseconds);
  }

  Future<void> _loadLastPlayedSong() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSongPath = prefs.getString('last_played_song_path');
    final lastIndex = prefs.getInt('last_played_index') ?? 0;
    final lastPosition = prefs.getInt('last_played_position') ?? 0;

    if (lastSongPath != null) {
      _currentIndex = lastIndex;
      
      if (lastPosition > 0) {
        Future.delayed(const Duration(milliseconds: 500), () {
          seek(Duration(milliseconds: lastPosition));
        });
      }
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
