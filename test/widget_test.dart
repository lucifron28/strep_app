import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strep_app/main.dart';
import 'package:strep_app/providers/music_provider.dart';
import 'package:strep_app/screens/music_list_screen.dart';
import 'package:strep_app/services/download_manager_service.dart';
import 'package:strep_app/widgets/youtube_download_dialog.dart';

import 'download_manager_test.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Strep app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StrepApp());
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Strep'), findsOneWidget);
  });

  testWidgets('YouTube dialog shows invalid URL errors', (tester) async {
    final manager = DownloadManagerService.forTesting(
      youtubeService: FakeYouTubeDownloadService(autoComplete: true),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DownloadManagerService>.value(value: manager),
          ChangeNotifierProvider(
            create: (_) => MusicProvider(downloadManager: manager),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: YouTubeDownloadDialog(onSongDownloaded: (_) {})),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'not a youtube url');
    await tester.tap(find.text('Get Video Info'));
    await tester.pump();

    expect(find.text('Enter a valid YouTube video URL.'), findsOneWidget);

    manager.dispose();
  });

  testWidgets('empty library state is clear', (tester) async {
    final manager = DownloadManagerService.forTesting(
      youtubeService: FakeYouTubeDownloadService(autoComplete: true),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DownloadManagerService>.value(value: manager),
          ChangeNotifierProvider(
            create: (_) => MusicProvider(
              downloadManager: manager,
              listenToDownloads: false,
            ),
          ),
        ],
        child: const MaterialApp(home: MusicListScreen()),
      ),
    );

    expect(find.text('Welcome to Strep!'), findsOneWidget);
    expect(find.textContaining('Import MP3, M4A'), findsOneWidget);

    manager.dispose();
  });
}
