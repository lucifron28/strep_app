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
    final songMaps = songs.map((song) => song.toJson()).toList();
    final jsonString = jsonEncode(songMaps);
    await prefs.setString(_songsKey, jsonString);
  }

  Future<List<Song>> loadSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_songsKey);

    if (jsonString == null) return [];

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((songMap) => Song.fromJson(Map<String, dynamic>.from(songMap)))
          .where((song) => song.path.isNotEmpty)
          .toList();
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
    final existingIds = existingSongs.map((s) => s.id).toSet();

    final songsToAdd = newSongs
        .where(
          (song) =>
              !existingPaths.contains(song.path) &&
              !existingIds.contains(song.id),
        )
        .toList();

    if (songsToAdd.isNotEmpty) {
      existingSongs.addAll(songsToAdd);
      await saveSongs(existingSongs);
    }
  }

  Future<bool> addSong(Song song) async {
    final existingSongs = await loadSongs();
    final exists = existingSongs.any(
      (existing) => existing.path == song.path || existing.id == song.id,
    );

    if (exists) return false;

    existingSongs.add(song);
    await saveSongs(existingSongs);
    return true;
  }

  Future<void> clearSongs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_songsKey);
  }
}
