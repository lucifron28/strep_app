import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strep_app/models/song.dart';
import 'package:strep_app/services/song_storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Song serializes and deserializes all persisted fields', () {
    final dateAdded = DateTime.utc(2026, 5, 10);
    final song = Song(
      id: 'youtube:abc123def45',
      title: 'A Song',
      artist: 'An Artist',
      album: 'An Album',
      path: '/music/a-song.webm',
      duration: const Duration(minutes: 3, seconds: 12),
      albumArt: '/art/a-song.jpg',
      customThumbnail: '/thumbs/a-song.jpg',
      source: 'youtube',
      youtubeVideoId: 'abc123def45',
      originalUrl: 'https://youtu.be/abc123def45',
      dateAdded: dateAdded,
    );

    final restored = Song.fromJson(song.toJson());

    expect(restored.id, song.id);
    expect(restored.title, song.title);
    expect(restored.artist, song.artist);
    expect(restored.album, song.album);
    expect(restored.path, song.path);
    expect(restored.duration, song.duration);
    expect(restored.albumArt, song.albumArt);
    expect(restored.customThumbnail, song.customThumbnail);
    expect(restored.source, song.source);
    expect(restored.youtubeVideoId, song.youtubeVideoId);
    expect(restored.originalUrl, song.originalUrl);
    expect(restored.dateAdded, dateAdded);
  });

  test('Song.fromJson supports the old saved format', () {
    final song = Song.fromJson({
      'title': 'Old Song',
      'artist': 'Old Artist',
      'album': 'Old Album',
      'path': '/music/old.mp3',
      'customThumbnail': '/thumbs/old.jpg',
    });

    expect(song.title, 'Old Song');
    expect(song.artist, 'Old Artist');
    expect(song.album, 'Old Album');
    expect(song.path, '/music/old.mp3');
    expect(song.customThumbnail, '/thumbs/old.jpg');
    expect(song.source, 'local');
    expect(song.duration, isNull);
    expect(song.id, 'local:/music/old.mp3');
  });

  test('SongStorageService saves and loads songs', () async {
    final service = SongStorageService();
    final song = Song(
      title: 'Stored Song',
      artist: 'Stored Artist',
      album: 'Stored Album',
      path: '/music/stored.flac',
      duration: const Duration(seconds: 42),
    );

    await service.saveSongs([song]);
    final loaded = await service.loadSongs();

    expect(loaded, hasLength(1));
    expect(loaded.single.title, 'Stored Song');
    expect(loaded.single.duration, const Duration(seconds: 42));
  });

  test('SongStorageService loads old stored JSON', () async {
    SharedPreferences.setMockInitialValues({
      'imported_songs': jsonEncode([
        {
          'title': 'Legacy',
          'artist': 'Legacy Artist',
          'album': 'Legacy Album',
          'path': '/music/legacy.mp3',
        },
      ]),
    });

    final loaded = await SongStorageService().loadSongs();

    expect(loaded, hasLength(1));
    expect(loaded.single.title, 'Legacy');
    expect(loaded.single.source, 'local');
  });
}
