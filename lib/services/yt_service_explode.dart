import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/song.dart';
import '../utils/debug_logger.dart';

enum DownloadFailureType {
  invalidUrl,
  videoInfo,
  videoUnavailable,
  noAudioStream,
  network,
  cancelled,
  fileWrite,
  unknown,
}

class DownloadResult {
  final Song? song;
  final DownloadFailureType? failureType;
  final String? message;

  const DownloadResult._({this.song, this.failureType, this.message});

  factory DownloadResult.success(Song song) => DownloadResult._(song: song);

  factory DownloadResult.failure(DownloadFailureType type, String message) =>
      DownloadResult._(failureType: type, message: message);

  factory DownloadResult.cancelled() => DownloadResult.failure(
    DownloadFailureType.cancelled,
    'Download cancelled.',
  );

  bool get isSuccess => song != null;
}

class VideoInfoResult {
  final VideoInfo? info;
  final DownloadFailureType? failureType;
  final String? message;

  const VideoInfoResult._({this.info, this.failureType, this.message});

  factory VideoInfoResult.success(VideoInfo info) =>
      VideoInfoResult._(info: info);

  factory VideoInfoResult.failure(DownloadFailureType type, String message) =>
      VideoInfoResult._(failureType: type, message: message);

  bool get isSuccess => info != null;
}

class DownloadCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class _DownloadCancelledException implements Exception {}

class YouTubeDownloadService {
  static final YouTubeDownloadService _instance =
      YouTubeDownloadService._internal();

  factory YouTubeDownloadService() => _instance;

  YouTubeDownloadService._internal();

  final YoutubeExplode _yt = YoutubeExplode();

  DownloadCancellationToken createCancellationToken() {
    return DownloadCancellationToken();
  }

  Future<DownloadResult> downloadYouTubeAudio(
    String url, {
    void Function(double progress)? onProgress,
    DownloadCancellationToken? cancellationToken,
  }) async {
    final token = cancellationToken ?? DownloadCancellationToken();
    File? partialFile;

    try {
      final videoId = _parseVideoId(url);
      if (videoId == null) {
        return DownloadResult.failure(
          DownloadFailureType.invalidUrl,
          'Enter a valid YouTube video URL.',
        );
      }

      DebugLogger.log('Starting YouTube download: $videoId');

      final video = await _getVideo(videoId);
      final manifest = await _getManifest(videoId);
      final audioStreams = manifest.audioOnly;

      if (audioStreams.isEmpty) {
        return DownloadResult.failure(
          DownloadFailureType.noAudioStream,
          'No downloadable audio stream was found for this video.',
        );
      }

      final audioStreamInfo = audioStreams.withHighestBitrate();
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(
        '${appDir.path}${Platform.pathSeparator}Music',
      );
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      final extension = audioStreamInfo.container.name.toLowerCase();
      final sanitizedTitle = sanitizeFilename(video.title, fallback: videoId);
      final finalFile = await uniqueFileFor(
        directory: musicDir,
        baseName: sanitizedTitle,
        extension: extension,
      );
      partialFile = File('${finalFile.path}.part');

      await _writeStreamToFile(
        streamInfo: audioStreamInfo,
        partialFile: partialFile,
        token: token,
        onProgress: onProgress,
      );

      if (token.isCancelled) {
        throw _DownloadCancelledException();
      }

      final completedFile = await partialFile.rename(finalFile.path);
      final song = Song(
        title: video.title,
        artist: video.author,
        album: 'YouTube Downloads',
        path: completedFile.path,
        duration: video.duration,
        source: 'youtube',
        youtubeVideoId: videoId,
        originalUrl: url,
        dateAdded: DateTime.now(),
      );

      DebugLogger.log('Download completed: ${completedFile.path}');
      return DownloadResult.success(song);
    } on _DownloadCancelledException {
      await _deleteIfExists(partialFile);
      return DownloadResult.cancelled();
    } on VideoUnavailableException catch (e, stackTrace) {
      await _deleteIfExists(partialFile);
      DebugLogger.log('YouTube video unavailable: $e\n$stackTrace');
      return DownloadResult.failure(
        DownloadFailureType.videoUnavailable,
        'This video is unavailable.',
      );
    } on VideoUnplayableException catch (e, stackTrace) {
      await _deleteIfExists(partialFile);
      DebugLogger.log('YouTube video unplayable: $e\n$stackTrace');
      return DownloadResult.failure(
        DownloadFailureType.videoUnavailable,
        'This video cannot be downloaded.',
      );
    } on SocketException catch (e, stackTrace) {
      await _deleteIfExists(partialFile);
      DebugLogger.log('Network error during YouTube download: $e\n$stackTrace');
      return DownloadResult.failure(
        DownloadFailureType.network,
        'Network error while downloading. Check your connection and try again.',
      );
    } on FileSystemException catch (e, stackTrace) {
      await _deleteIfExists(partialFile);
      DebugLogger.log(
        'File write error during YouTube download: $e\n$stackTrace',
      );
      return DownloadResult.failure(
        DownloadFailureType.fileWrite,
        'Could not save the downloaded audio file.',
      );
    } catch (e, stackTrace) {
      await _deleteIfExists(partialFile);
      DebugLogger.log('YouTube download error: $e\n$stackTrace');
      return DownloadResult.failure(
        DownloadFailureType.unknown,
        'Download failed. Please try again.',
      );
    }
  }

  Future<VideoInfoResult> getVideoInfoResult(String url) async {
    try {
      final videoId = _parseVideoId(url);
      if (videoId == null) {
        return VideoInfoResult.failure(
          DownloadFailureType.invalidUrl,
          'Enter a valid YouTube video URL.',
        );
      }

      final video = await _getVideo(videoId);
      return VideoInfoResult.success(
        VideoInfo(
          title: video.title,
          author: video.author,
          duration: video.duration,
          thumbnailUrl: video.thumbnails.highResUrl,
          description: video.description,
          videoId: videoId,
          originalUrl: url,
        ),
      );
    } on VideoUnavailableException catch (e, stackTrace) {
      DebugLogger.log('Failed to get video info: $e\n$stackTrace');
      return VideoInfoResult.failure(
        DownloadFailureType.videoUnavailable,
        'This video is unavailable.',
      );
    } on VideoUnplayableException catch (e, stackTrace) {
      DebugLogger.log('Failed to get playable video info: $e\n$stackTrace');
      return VideoInfoResult.failure(
        DownloadFailureType.videoUnavailable,
        'This video cannot be downloaded.',
      );
    } on SocketException catch (e, stackTrace) {
      DebugLogger.log('Network error fetching video info: $e\n$stackTrace');
      return VideoInfoResult.failure(
        DownloadFailureType.network,
        'Network error while fetching video information.',
      );
    } catch (e, stackTrace) {
      DebugLogger.log('Failed to get video info: $e\n$stackTrace');
      return VideoInfoResult.failure(
        DownloadFailureType.videoInfo,
        'Could not fetch video information.',
      );
    }
  }

  Future<VideoInfo?> getVideoInfo(String url) async {
    final result = await getVideoInfoResult(url);
    return result.info;
  }

  bool isValidYouTubeUrl(String url) => _parseVideoId(url) != null;

  static String? parseVideoId(String url) => VideoId.parseVideoId(url.trim());

  static String sanitizeFilename(String filename, {String fallback = 'audio'}) {
    final sanitized = filename
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return sanitized.isEmpty ? fallback : sanitized;
  }

  static Future<File> uniqueFileFor({
    required Directory directory,
    required String baseName,
    required String extension,
  }) async {
    final cleanExtension = extension.replaceFirst(RegExp(r'^\.'), '');
    var candidate = File(
      '${directory.path}${Platform.pathSeparator}$baseName.$cleanExtension',
    );
    var index = 1;

    while (await candidate.exists() ||
        await File('${candidate.path}.part').exists()) {
      candidate = File(
        '${directory.path}${Platform.pathSeparator}$baseName ($index).$cleanExtension',
      );
      index++;
    }

    return candidate;
  }

  String? _parseVideoId(String url) => parseVideoId(url);

  Future<Video> _getVideo(String videoId) async {
    try {
      return await _yt.videos.get(VideoId(videoId));
    } on SocketException {
      rethrow;
    } on YoutubeExplodeException {
      rethrow;
    } catch (e) {
      throw YoutubeExplodeException('Could not fetch video information: $e');
    }
  }

  Future<StreamManifest> _getManifest(String videoId) async {
    try {
      return await _yt.videos.streamsClient.getManifest(VideoId(videoId));
    } on SocketException {
      rethrow;
    } on YoutubeExplodeException {
      rethrow;
    } catch (e) {
      throw YoutubeExplodeException('Could not fetch stream information: $e');
    }
  }

  Future<void> _writeStreamToFile({
    required AudioOnlyStreamInfo streamInfo,
    required File partialFile,
    required DownloadCancellationToken token,
    void Function(double progress)? onProgress,
  }) async {
    IOSink? output;
    var downloaded = 0;
    final totalSize = streamInfo.size.totalBytes;

    try {
      final stream = _yt.videos.streamsClient.get(streamInfo);
      output = partialFile.openWrite();

      await for (final chunk in stream) {
        if (token.isCancelled) {
          throw _DownloadCancelledException();
        }

        output.add(chunk);
        downloaded += chunk.length;

        if (onProgress != null && totalSize > 0) {
          onProgress((downloaded / totalSize).clamp(0.0, 1.0));
        }
      }

      await output.flush();
      await output.close();
      output = null;
    } finally {
      if (output != null) {
        await output.flush();
        await output.close();
      }
    }
  }

  Future<void> _deleteIfExists(File? file) async {
    if (file == null) return;

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      DebugLogger.log('Could not delete partial download ${file.path}: $e');
    }
  }

  void dispose() {
    // The service is a shared singleton. Keep the YoutubeExplode client alive so
    // later direct or background downloads do not fail after one provider closes.
  }
}

class VideoInfo {
  final String title;
  final String author;
  final Duration? duration;
  final String? thumbnailUrl;
  final String description;
  final String videoId;
  final String originalUrl;

  VideoInfo({
    required this.title,
    required this.author,
    this.duration,
    this.thumbnailUrl,
    required this.description,
    required this.videoId,
    required this.originalUrl,
  });
}
