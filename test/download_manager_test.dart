import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strep_app/models/song.dart';
import 'package:strep_app/providers/music_provider.dart';
import 'package:strep_app/services/download_manager_service.dart';
import 'package:strep_app/services/song_storage_service.dart';
import 'package:strep_app/services/yt_service_explode.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('DownloadManagerService moves a download to completed', () async {
    final fakeService = FakeYouTubeDownloadService(autoComplete: true);
    final manager = DownloadManagerService.forTesting(
      youtubeService: fakeService,
    );

    final id = await manager.startDownload(
      url: 'https://youtu.be/dQw4w9WgXcQ',
      title: 'Test',
      artist: 'Tester',
    );

    await waitFor(
      () => manager.downloadsById(id).status == DownloadStatus.completed,
    );

    final item = manager.downloadsById(id);
    expect(item.progress, 1.0);
    expect(item.completedSong, isNotNull);

    manager.dispose();
  });

  test('cancelling a queued download prevents it from starting', () async {
    final fakeService = FakeYouTubeDownloadService(autoComplete: false);
    final manager = DownloadManagerService.forTesting(
      youtubeService: fakeService,
    );

    final firstId = await manager.startDownload(
      url: 'https://youtu.be/dQw4w9WgXcQ',
      title: 'First',
      artist: 'Tester',
    );
    await fakeService.started.future;

    final secondId = await manager.startDownload(
      url: 'https://youtu.be/oHg5SJYRHA0',
      title: 'Second',
      artist: 'Tester',
    );

    manager.cancelDownload(secondId);
    manager.cancelDownload(firstId);

    expect(manager.downloadsById(secondId).status, DownloadStatus.cancelled);
    await waitFor(
      () => manager.downloadsById(firstId).status == DownloadStatus.cancelled,
    );
    expect(fakeService.downloadCallCount, 1);

    manager.dispose();
  });

  test('cancelling an active download stops the service token', () async {
    final fakeService = FakeYouTubeDownloadService(autoComplete: false);
    final manager = DownloadManagerService.forTesting(
      youtubeService: fakeService,
    );

    final id = await manager.startDownload(
      url: 'https://youtu.be/dQw4w9WgXcQ',
      title: 'Active',
      artist: 'Tester',
    );

    await waitFor(
      () => manager.downloadsById(id).status == DownloadStatus.downloading,
    );
    manager.cancelDownload(id);

    await waitFor(() => fakeService.lastToken?.isCancelled == true);
    await waitFor(
      () => manager.downloadsById(id).status == DownloadStatus.cancelled,
    );

    manager.dispose();
  });

  test('MusicProvider persists a completed background download', () async {
    final fakeService = FakeYouTubeDownloadService(autoComplete: true);
    final manager = DownloadManagerService.forTesting(
      youtubeService: fakeService,
    );
    final provider = MusicProvider(downloadManager: manager);

    await manager.startDownload(
      url: 'https://youtu.be/dQw4w9WgXcQ',
      title: 'Persisted',
      artist: 'Tester',
    );

    await waitFor(() => provider.songs.isNotEmpty);
    await waitForAsync(
      () async => (await SongStorageService().loadSongs()).isNotEmpty,
    );

    final storedSongs = await SongStorageService().loadSongs();
    expect(provider.songs.single.title, 'Downloaded Song');
    expect(storedSongs, hasLength(1));
    expect(storedSongs.single.source, 'youtube');

    provider.dispose();
    manager.dispose();
  });
}

extension on DownloadManagerService {
  DownloadItem downloadsById(String id) {
    return downloads.firstWhere((item) => item.id == id);
  }
}

Future<void> waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final stopwatch = Stopwatch()..start();
  while (!condition()) {
    if (stopwatch.elapsed > timeout) {
      fail('Timed out waiting for condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<void> waitForAsync(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final stopwatch = Stopwatch()..start();
  while (!await condition()) {
    if (stopwatch.elapsed > timeout) {
      fail('Timed out waiting for async condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class FakeYouTubeDownloadService implements YouTubeDownloadService {
  FakeYouTubeDownloadService({required this.autoComplete}) {
    if (autoComplete) {
      _release.complete();
    }
  }

  final bool autoComplete;
  final Completer<void> started = Completer<void>();
  final Completer<void> _release = Completer<void>();
  int downloadCallCount = 0;
  DownloadCancellationToken? lastToken;

  void release() {
    if (!_release.isCompleted) {
      _release.complete();
    }
  }

  @override
  DownloadCancellationToken createCancellationToken() {
    return DownloadCancellationToken();
  }

  @override
  Future<DownloadResult> downloadYouTubeAudio(
    String url, {
    void Function(double progress)? onProgress,
    DownloadCancellationToken? cancellationToken,
  }) async {
    downloadCallCount++;
    lastToken = cancellationToken;
    if (!started.isCompleted) {
      started.complete();
    }

    onProgress?.call(0.25);
    while (!_release.isCompleted) {
      if (cancellationToken?.isCancelled ?? false) {
        return DownloadResult.cancelled();
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    if (cancellationToken?.isCancelled ?? false) {
      return DownloadResult.cancelled();
    }

    onProgress?.call(1.0);
    return DownloadResult.success(
      Song(
        title: 'Downloaded Song',
        artist: 'Tester',
        album: 'YouTube Downloads',
        path: '/tmp/downloaded-song.webm',
        duration: const Duration(minutes: 2),
        source: 'youtube',
        youtubeVideoId: 'dQw4w9WgXcQ',
        originalUrl: url,
      ),
    );
  }

  @override
  Future<VideoInfo?> getVideoInfo(String url) async => null;

  @override
  Future<VideoInfoResult> getVideoInfoResult(String url) async {
    return VideoInfoResult.failure(
      DownloadFailureType.videoInfo,
      'Not implemented in fake.',
    );
  }

  @override
  bool isValidYouTubeUrl(String url) => true;

  @override
  void dispose() {}
}
