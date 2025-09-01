import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/song.dart';
import '../utils/debug_logger.dart';

class YouTubeDownloadService {
  static final YouTubeDownloadService _instance = YouTubeDownloadService._internal();
  factory YouTubeDownloadService() => _instance;
  YouTubeDownloadService._internal();

  final YoutubeExplode _yt = YoutubeExplode();

  /// Download audio from YouTube URL and return Song object
  Future<Song?> downloadYouTubeAudio(String url, {Function(double)? onProgress}) async {
    try {
      DebugLogger.log('Starting YouTube download: $url');
      
      // Get video info
      final video = await _yt.videos.get(url);
      DebugLogger.log('Video info: ${video.title} by ${video.author}');

      // Get audio stream
      final manifest = await _yt.videos.streamsClient.getManifest(url);
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      
      DebugLogger.log('Audio bitrate: ${audioStreamInfo.bitrate}');

      // Create file path
      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/Music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      // Sanitize filename
      final sanitizedTitle = _sanitizeFilename(video.title);
      final extension = audioStreamInfo.container.name.toLowerCase();
      final filePath = '${musicDir.path}/$sanitizedTitle.$extension';
      final file = File(filePath);

      // Download audio stream
      final stream = _yt.videos.streamsClient.get(audioStreamInfo);
      final output = file.openWrite();
      
      int downloaded = 0;
      final totalSize = audioStreamInfo.size.totalBytes;
      
      await for (final chunk in stream) {
        output.add(chunk);
        downloaded += chunk.length;
        
        if (onProgress != null && totalSize > 0) {
          final progress = downloaded / totalSize;
          onProgress(progress);
        }
      }

      await output.flush();
      await output.close();

      DebugLogger.log('Download completed: $filePath');

      // Create Song object
      final song = Song(
        title: video.title,
        artist: video.author,
        album: 'YouTube Downloads',
        path: filePath,
        duration: video.duration,
      );

      return song;

    } catch (e) {
      DebugLogger.log('YouTube download error: $e');
      return null;
    }
  }

  /// Extract video info without downloading
  Future<VideoInfo?> getVideoInfo(String url) async {
    try {
      final video = await _yt.videos.get(url);
      return VideoInfo(
        title: video.title,
        author: video.author,
        duration: video.duration,
        thumbnailUrl: video.thumbnails.highResUrl,
        description: video.description,
      );
    } catch (e) {
      DebugLogger.log('Failed to get video info: $e');
      return null;
    }
  }

  /// Check if URL is valid YouTube URL
  bool isValidYouTubeUrl(String url) {
    try {
      final videoId = VideoId.parseVideoId(url);
      return videoId != null;
    } catch (e) {
      return false;
    }
  }

  /// Sanitize filename for file system
  String _sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Clean up resources
  void dispose() {
    _yt.close();
  }
}

/// Video information class
class VideoInfo {
  final String title;
  final String author;
  final Duration? duration;
  final String? thumbnailUrl;
  final String description;

  VideoInfo({
    required this.title,
    required this.author,
    this.duration,
    this.thumbnailUrl,
    required this.description,
  });
}