import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/dracula_theme.dart';
import 'providers/music_provider.dart';
import 'screens/music_list_screen.dart';

void main() {
  runApp(const StrepApp());
}

class StrepApp extends StatelessWidget {
  const StrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MusicProvider()..initialize(),
      child: MaterialApp(
        title: 'Strep MP3 Player',
        theme: DraculaTheme.theme,
        home: const MusicListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
