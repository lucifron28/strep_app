import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/dracula_theme.dart';
import '../widgets/strep_icon.dart';
import '../models/song.dart';

class SongThumbnail extends StatelessWidget {
  final Song song;
  final double size;
  final BorderRadius borderRadius;
  final bool isCurrentSong;
  final bool showPlayIcon;

  const SongThumbnail({
    super.key,
    required this.song,
    required this.size,
    required this.borderRadius,
    this.isCurrentSong = false,
    this.showPlayIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isCurrentSong ? DraculaTheme.purple : DraculaTheme.selection,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background thumbnail
            _buildThumbnailImage(),
            // Play/pause icon overlay
            if (showPlayIcon && isCurrentSong)
              Container(
                color: DraculaTheme.background.withValues(alpha: 0.8),
                child: Icon(
                  Icons.pause,
                  color: DraculaTheme.foreground,
                  size: size * 0.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailImage() {
    // If song has custom thumbnail, display it
    if (song.customThumbnail != null && song.customThumbnail!.isNotEmpty) {
      final imageFile = File(song.customThumbnail!);
      if (imageFile.existsSync()) {
        return Image.file(
          imageFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultThumbnail();
          },
        );
      }
    }

    // If song has album art, display it
    if (song.albumArt != null && song.albumArt!.isNotEmpty) {
      final albumArtFile = File(song.albumArt!);
      if (albumArtFile.existsSync()) {
        return Image.file(
          albumArtFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultThumbnail();
          },
        );
      }
    }

    // Default Strep icon
    return _buildDefaultThumbnail();
  }

  Widget _buildDefaultThumbnail() {
    return Padding(
      padding: EdgeInsets.all(size * 0.2),
      child: StrepIcon(
        size: size * 0.6,
        borderRadius: BorderRadius.circular(size * 0.1),
      ),
    );
  }
}
