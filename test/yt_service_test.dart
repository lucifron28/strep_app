import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:strep_app/services/yt_service_explode.dart';

void main() {
  test('validates YouTube URLs without network access', () {
    final service = YouTubeDownloadService();

    expect(service.isValidYouTubeUrl('https://youtu.be/dQw4w9WgXcQ'), isTrue);
    expect(
      service.isValidYouTubeUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
      isTrue,
    );
    expect(service.isValidYouTubeUrl('https://example.com/nope'), isFalse);
    expect(service.isValidYouTubeUrl('not a url'), isFalse);
  });

  test('sanitizes filenames', () {
    expect(
      YouTubeDownloadService.sanitizeFilename('  A:/bad* title??  '),
      'A bad title',
    );
    expect(
      YouTubeDownloadService.sanitizeFilename('     ', fallback: 'fallback'),
      'fallback',
    );
  });

  test(
    'generates unique filenames without overwriting existing files',
    () async {
      final dir = await Directory.systemTemp.createTemp('strep_filename_test');
      try {
        await File(
          '${dir.path}${Platform.pathSeparator}Title.webm',
        ).writeAsString('existing');
        await File(
          '${dir.path}${Platform.pathSeparator}Title (1).webm',
        ).writeAsString('existing');

        final file = await YouTubeDownloadService.uniqueFileFor(
          directory: dir,
          baseName: 'Title',
          extension: 'webm',
        );

        expect(file.path, endsWith('Title (2).webm'));
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
