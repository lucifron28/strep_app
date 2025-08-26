import 'package:flutter/material.dart';
import '../theme/dracula_theme.dart';
import '../widgets/strep_icon.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DraculaTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: DraculaTheme.purple.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: StrepIcon(
                size: 120,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Name
            Text(
              'Strep',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: DraculaTheme.foreground,
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'MP3 Player',
              style: TextStyle(
                fontSize: 18,
                color: DraculaTheme.comment,
                letterSpacing: 1,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              color: DraculaTheme.purple,
            ),
          ],
        ),
      ),
    );
  }
}
