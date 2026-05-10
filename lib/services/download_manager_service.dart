import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/song.dart';
import '../services/yt_service_explode.dart';

enum DownloadStatus { queued, downloading, completed, failed, cancelled }

class DownloadItem {
  final String id;
  final String url;
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final double progress;
  final DownloadStatus status;
  final Song? completedSong;
  final String? errorMessage;

  const DownloadItem({
    required this.id,
    required this.url,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    this.progress = 0.0,
    this.status = DownloadStatus.queued,
    this.completedSong,
    this.errorMessage,
  });

  DownloadItem copyWith({
    String? id,
    String? url,
    String? title,
    String? artist,
    String? thumbnailUrl,
    double? progress,
    DownloadStatus? status,
    Song? completedSong,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      completedSong: completedSong ?? this.completedSong,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class DownloadManagerService extends ChangeNotifier {
  static final DownloadManagerService _instance =
      DownloadManagerService._internal(YouTubeDownloadService());

  factory DownloadManagerService() => _instance;

  DownloadManagerService._internal(this._youtubeService);

  @visibleForTesting
  DownloadManagerService.forTesting({
    required YouTubeDownloadService youtubeService,
  }) : _youtubeService = youtubeService;

  final YouTubeDownloadService _youtubeService;
  final Map<String, DownloadItem> _downloads = {};
  final Map<String, StreamController<DownloadItem>> _progressControllers = {};
  final Map<String, DownloadCancellationToken> _cancellationTokens = {};
  bool _isProcessing = false;
  bool _disposed = false;

  List<DownloadItem> get downloads => _downloads.values.toList();

  List<DownloadItem> get activeDownloads => _downloads.values
      .where(
        (item) =>
            item.status == DownloadStatus.downloading ||
            item.status == DownloadStatus.queued,
      )
      .toList();

  List<DownloadItem> get visibleDownloads => _downloads.values
      .where((item) => item.status != DownloadStatus.completed)
      .toList();

  List<DownloadItem> get completedDownloads => _downloads.values
      .where((item) => item.status == DownloadStatus.completed)
      .toList();

  Stream<DownloadItem> getDownloadStream(String id) {
    _progressControllers[id] ??= StreamController<DownloadItem>.broadcast();
    return _progressControllers[id]!.stream;
  }

  Future<String> startDownload({
    required String url,
    required String title,
    required String artist,
    String? thumbnailUrl,
  }) async {
    DownloadItem? existing;
    for (final item in activeDownloads) {
      if (item.url.trim() == url.trim()) {
        existing = item;
        break;
      }
    }

    if (existing != null) {
      return existing.id;
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final downloadItem = DownloadItem(
      id: id,
      url: url,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
    );

    _downloads[id] = downloadItem;
    _progressControllers[id] = StreamController<DownloadItem>.broadcast();
    _notifyDownloadChanged(downloadItem);

    unawaited(_processDownloadQueue());
    return id;
  }

  Future<void> retryDownload(String id) async {
    final item = _downloads[id];
    if (item == null) return;
    if (item.status != DownloadStatus.failed &&
        item.status != DownloadStatus.cancelled) {
      return;
    }

    _updateDownloadItem(
      id,
      item.copyWith(
        status: DownloadStatus.queued,
        progress: 0.0,
        clearError: true,
      ),
    );
    await _processDownloadQueue();
  }

  Future<void> _processDownloadQueue() async {
    if (_isProcessing || _disposed) return;
    _isProcessing = true;

    try {
      while (!_disposed) {
        final queuedDownloads = _downloads.values
            .where((item) => item.status == DownloadStatus.queued)
            .toList();

        if (queuedDownloads.isEmpty) break;

        await _processDownload(queuedDownloads.first);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processDownload(DownloadItem downloadItem) async {
    final current = _downloads[downloadItem.id];
    if (current == null || current.status != DownloadStatus.queued) return;

    final token = _youtubeService.createCancellationToken();
    _cancellationTokens[downloadItem.id] = token;

    _updateDownloadItem(
      downloadItem.id,
      current.copyWith(
        status: DownloadStatus.downloading,
        progress: 0.0,
        clearError: true,
      ),
    );

    final result = await _youtubeService.downloadYouTubeAudio(
      downloadItem.url,
      cancellationToken: token,
      onProgress: (progress) {
        final latest = _downloads[downloadItem.id];
        if (latest == null || latest.status != DownloadStatus.downloading) {
          return;
        }

        final shouldNotify =
            progress >= 1.0 || (progress - latest.progress).abs() >= 0.01;
        if (!shouldNotify) return;

        _updateDownloadItem(
          downloadItem.id,
          latest.copyWith(progress: progress),
        );
      },
    );

    _cancellationTokens.remove(downloadItem.id);

    final latest = _downloads[downloadItem.id];
    if (latest == null) return;

    if (latest.status == DownloadStatus.cancelled ||
        result.failureType == DownloadFailureType.cancelled) {
      _updateDownloadItem(
        downloadItem.id,
        latest.copyWith(
          status: DownloadStatus.cancelled,
          errorMessage: result.message ?? 'Download cancelled.',
        ),
      );
      return;
    }

    if (result.song != null) {
      _updateDownloadItem(
        downloadItem.id,
        latest.copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
          completedSong: result.song,
          clearError: true,
        ),
      );
      return;
    }

    _updateDownloadItem(
      downloadItem.id,
      latest.copyWith(
        status: DownloadStatus.failed,
        errorMessage: result.message ?? 'Download failed.',
      ),
    );
  }

  void cancelDownload(String id) {
    final item = _downloads[id];
    if (item == null) return;

    if (item.status == DownloadStatus.queued) {
      _updateDownloadItem(
        id,
        item.copyWith(
          status: DownloadStatus.cancelled,
          errorMessage: 'Download cancelled.',
        ),
      );
      return;
    }

    if (item.status == DownloadStatus.downloading) {
      _cancellationTokens[id]?.cancel();
      _updateDownloadItem(
        id,
        item.copyWith(
          status: DownloadStatus.cancelled,
          errorMessage: 'Download cancelled.',
        ),
      );
    }
  }

  void removeDownload(String id) {
    _cancellationTokens[id]?.cancel();
    _cancellationTokens.remove(id);
    _downloads.remove(id);
    _progressControllers[id]?.close();
    _progressControllers.remove(id);
    _safeNotifyListeners();
  }

  void clearCompleted() {
    final completedIds = completedDownloads.map((item) => item.id).toList();
    for (final id in completedIds) {
      removeDownload(id);
    }
  }

  void _updateDownloadItem(String id, DownloadItem updatedItem) {
    if (!_downloads.containsKey(id)) return;
    _downloads[id] = updatedItem;
    _notifyDownloadChanged(updatedItem);
  }

  void _notifyDownloadChanged(DownloadItem item) {
    _progressControllers[item.id]?.add(item);
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final token in _cancellationTokens.values) {
      token.cancel();
    }
    _cancellationTokens.clear();
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    super.dispose();
  }
}
