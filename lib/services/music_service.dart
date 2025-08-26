import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';
import '../utils/debug_logger.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    
    if (status.isDenied) {
      status = await Permission.storage.request();
    }

    if (status.isDenied) {
      var manageExternalStorageStatus = await Permission.manageExternalStorage.status;
      if (manageExternalStorageStatus.isDenied) {
        manageExternalStorageStatus = await Permission.manageExternalStorage.request();
      }
      return manageExternalStorageStatus.isGranted;
    }

    return status.isGranted;
  }

  Future<List<Song>> loadMusicFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<Song> songs = [];
        for (PlatformFile file in result.files) {
          if (file.path != null) {
            songs.add(Song.fromPath(file.path!));
          }
        }
        return songs;
      }

      return await _searchForMusicFiles();
    } catch (e) {
      DebugLogger.log('Error loading music files: $e');
      return [];
    }
  }

  Future<List<Song>> _searchForMusicFiles() async {
    List<Song> songs = [];
    
    try {
      List<String> searchPaths = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/sdcard/Music',
        '/sdcard/Download',
      ];

      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          searchPaths.add(externalDir.path);
        }
      } catch (e) {
        DebugLogger.log('Could not access external storage directory: $e');
      }

      for (String path in searchPaths) {
        try {
          final directory = Directory(path);
          if (await directory.exists()) {
            await _scanDirectory(directory, songs);
          }
        } catch (e) {
          DebugLogger.log('Error scanning directory $path: $e');
        }
      }
    } catch (e) {
      DebugLogger.log('Error in music file search: $e');
    }

    return songs;
  }

  Future<void> _scanDirectory(Directory directory, List<Song> songs) async {
    try {
      await for (FileSystemEntity entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          songs.add(Song.fromPath(entity.path));
        }
      }
    } catch (e) {
      DebugLogger.log('Error scanning directory ${directory.path}: $e');
    }
  }
}
