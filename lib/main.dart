import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/dracula_theme.dart';
import 'providers/music_provider.dart';
import 'screens/music_list_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const StrepApp());
}

class StrepApp extends StatelessWidget {
  const StrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MusicProvider(),
      child: MaterialApp(
        title: 'Strep MP3 Player',
        theme: DraculaTheme.theme,
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Get the music provider and initialize
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    await musicProvider.initialize();
    
    // Add a small delay for better UX
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    }
    
    return const MusicListScreen();
  }
}
