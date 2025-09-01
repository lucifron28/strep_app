import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class SongMetadataService {
  static const String _metadataKey = 'song_metadata';
  
  static final SongMetadataService _instance = SongMetadataService._internal();
  factory SongMetadataService() => _instance;
  SongMetadataService._internal();

  // Save custom metadata for songs
  Future<void> saveSongMetadata(Map<String, Map<String, String>> metadata) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(metadata);
    await prefs.setString(_metadataKey, jsonString);
  }

  // Load custom metadata for songs
  Future<Map<String, Map<String, String>>> loadSongMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_metadataKey);
    
    if (jsonString == null) return {};
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map(
        (key, value) => MapEntry(
          key, 
          Map<String, String>.from(value as Map),
        ),
      );
    } catch (e) {
      return {};
    }
  }

  // Apply saved metadata to a song
  Future<Song> applySavedMetadata(Song song) async {
    final metadata = await loadSongMetadata();
    final songMetadata = metadata[song.path];
    
    if (songMetadata != null) {
      return song.copyWith(
        title: songMetadata['title'] ?? song.title,
        artist: songMetadata['artist'] ?? song.artist,
        album: songMetadata['album'] ?? song.album,
        customThumbnail: songMetadata['customThumbnail'],
      );
    }
    
    return song;
  }

  // Save metadata for a specific song
  Future<void> saveSongDetails(Song song) async {
    final metadata = await loadSongMetadata();
    
    metadata[song.path] = {
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      if (song.customThumbnail != null) 'customThumbnail': song.customThumbnail!,
    };
    
    await saveSongMetadata(metadata);
  }

  // Apply saved metadata to a list of songs
  Future<List<Song>> applyMetadataToSongs(List<Song> songs) async {
    final metadata = await loadSongMetadata();
    
    return songs.map((song) {
      final songMetadata = metadata[song.path];
      if (songMetadata != null) {
        return song.copyWith(
          title: songMetadata['title'] ?? song.title,
          artist: songMetadata['artist'] ?? song.artist,
          album: songMetadata['album'] ?? song.album,
          customThumbnail: songMetadata['customThumbnail'],
        );
      }
      return song;
    }).toList();
  }

  // Delete metadata for a specific song
  Future<void> deleteSongMetadata(String songPath) async {
    final metadata = await loadSongMetadata();
    metadata.remove(songPath);
    await saveSongMetadata(metadata);
  }

  // Clear all metadata
  Future<void> clearAllMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_metadataKey);
  }
}
