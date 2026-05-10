import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/song.dart';
import '../utils/debug_logger.dart';

class MusicPermissionResult {
  final bool granted;
  final bool permanentlyDenied;
  final String? message;

  const MusicPermissionResult({
    required this.granted,
    this.permanentlyDenied = false,
    this.message,
  });
}

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  static const List<String> supportedExtensions = [
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
    'webm',
  ];

  Future<bool> requestStoragePermission() async {
    final result = await requestAudioLibraryPermission();
    return result.granted;
  }

  Future<MusicPermissionResult> requestAudioLibraryPermission() async {
    if (!Platform.isAndroid) {
      return const MusicPermissionResult(granted: true);
    }

    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final permission = info.version.sdkInt >= 33
          ? Permission.audio
          : Permission.storage;
      var status = await permission.status;

      if (status.isDenied) {
        status = await permission.request();
      }

      if (status.isGranted || status.isLimited) {
        return const MusicPermissionResult(granted: true);
      }

      final permanentlyDenied = status.isPermanentlyDenied;
      return MusicPermissionResult(
        granted: false,
        permanentlyDenied: permanentlyDenied,
        message: permanentlyDenied
            ? 'Audio permission is permanently denied. Enable it in Android settings to scan device folders.'
            : 'Audio permission is required to scan device folders.',
      );
    } catch (e) {
      DebugLogger.log('Error requesting audio permission: $e');
      return const MusicPermissionResult(
        granted: false,
        message: 'Could not check audio permission.',
      );
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<List<Song>> loadMusicFiles() async {
    final permission = await requestAudioLibraryPermission();
    if (!permission.granted) {
      DebugLogger.log(permission.message ?? 'Audio permission denied');
      return [];
    }

    return _searchForMusicFiles();
  }

  Future<List<Song>> importMusicFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final songs = <Song>[];
      for (final file in result.files) {
        final path = file.path;
        if (path != null && isSupportedAudioFile(path)) {
          songs.add(Song.fromPath(path));
        }
      }
      return songs;
    } catch (e) {
      DebugLogger.log('Error importing music files: $e');
      return [];
    }
  }

  static bool isSupportedAudioFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return supportedExtensions.contains(extension);
  }

  Future<List<Song>> _searchForMusicFiles() async {
    final songs = <Song>[];

    try {
      final searchPaths = <String>[
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

      for (final path in searchPaths.toSet()) {
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
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && isSupportedAudioFile(entity.path)) {
          songs.add(Song.fromPath(entity.path));
        }
      }
    } catch (e) {
      DebugLogger.log('Error scanning directory ${directory.path}: $e');
    }
  }
}
