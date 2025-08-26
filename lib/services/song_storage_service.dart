import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class SongStorageService {
  static const String _songsKey = 'imported_songs';
  
  static final SongStorageService _instance = SongStorageService._internal();
  factory SongStorageService() => _instance;
  SongStorageService._internal();

  Future<void> saveSongs(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, String>> songMaps = songs.map((song) => {
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'path': song.path,
      if (song.customThumbnail != null) 'customThumbnail': song.customThumbnail!,
    }).toList();
    
    final jsonString = jsonEncode(songMaps);
    await prefs.setString(_songsKey, jsonString);
  }

  Future<List<Song>> loadSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_songsKey);
    
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> songMaps = jsonDecode(jsonString);
      return songMaps.map((songMap) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(songMap);
        return Song(
          title: map['title'] ?? 'Unknown Title',
          artist: map['artist'] ?? 'Unknown Artist',
          album: map['album'] ?? 'Unknown Album',
          path: map['path'] ?? '',
          customThumbnail: map['customThumbnail'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> hasSongs() async {
    final songs = await loadSongs();
    return songs.isNotEmpty;
  }

  Future<void> removeSong(String songPath) async {
    final songs = await loadSongs();
    songs.removeWhere((song) => song.path == songPath);
    await saveSongs(songs);
  }

  Future<void> addSongs(List<Song> newSongs) async {
    final existingSongs = await loadSongs();
    final existingPaths = existingSongs.map((s) => s.path).toSet();
    
    final songsToAdd = newSongs.where((song) => !existingPaths.contains(song.path)).toList();
    
    if (songsToAdd.isNotEmpty) {
      existingSongs.addAll(songsToAdd);
      await saveSongs(existingSongs);
    }
  }

  Future<void> clearSongs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_songsKey);
  }
}
