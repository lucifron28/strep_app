import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../services/audio_player_service.dart';
import '../theme/dracula_theme.dart';
import '../widgets/strep_icon.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<MusicProvider>(
        builder: (context, musicProvider, child) {
          final currentSong = musicProvider.currentSong;
          
          if (currentSong == null) {
            return const Center(
              child: Text('No song selected'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                
                // Album Art
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: DraculaTheme.currentLine,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: DraculaTheme.purple.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: currentSong.albumArt != null
                        ? Image.file(
                            File(currentSong.albumArt!),
                            fit: BoxFit.cover,
                          )
                        : StrepIcon(
                            size: 280,
                            borderRadius: BorderRadius.circular(16),
                          ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Song Info
                Text(
                  currentSong.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  currentSong.artist,
                  style: TextStyle(
                    fontSize: 18,
                    color: DraculaTheme.comment,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  currentSong.album,
                  style: TextStyle(
                    fontSize: 16,
                    color: DraculaTheme.comment,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),
                
                // Progress Bar
                _buildProgressBar(musicProvider),
                
                const SizedBox(height: 32),
                
                // Control Buttons
                _buildControlButtons(musicProvider),
                
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(MusicProvider musicProvider) {
    return StreamBuilder<Duration>(
      stream: musicProvider.audioService.positionStream,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration?>(
          stream: musicProvider.audioService.durationStream,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            
            return Column(
              children: [
                Slider(
                  value: duration.inMilliseconds > 0 
                      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0,
                  onChanged: (value) {
                    if (duration.inMilliseconds > 0) {
                      final newPosition = Duration(
                        milliseconds: (duration.inMilliseconds * value).round(),
                      );
                      musicProvider.seek(newPosition);
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(color: DraculaTheme.comment),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(color: DraculaTheme.comment),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControlButtons(MusicProvider musicProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous
        IconButton(
          onPressed: musicProvider.currentIndex > 0
              ? () => musicProvider.skipToPrevious()
              : null,
          icon: Icon(
            Icons.skip_previous,
            size: 40,
            color: musicProvider.currentIndex > 0
                ? DraculaTheme.purple
                : DraculaTheme.comment,
          ),
        ),
        
        // Play/Pause
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: DraculaTheme.purple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: DraculaTheme.purple.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: StreamBuilder<PlayerState>(
            stream: musicProvider.audioService.playerStateStream,
            builder: (context, snapshot) {
              final currentPlayerState = snapshot.data ?? musicProvider.playerState;
              return IconButton(
                onPressed: () => musicProvider.playPause(),
                icon: Icon(
                  currentPlayerState == PlayerState.playing
                      ? Icons.pause
                      : currentPlayerState == PlayerState.loading
                          ? Icons.hourglass_empty
                          : Icons.play_arrow,
                  size: 40,
                  color: DraculaTheme.background,
                ),
              );
            },
          ),
        ),
        
        // Next
        IconButton(
          onPressed: musicProvider.currentIndex < musicProvider.songs.length - 1
              ? () => musicProvider.skipToNext()
              : null,
          icon: Icon(
            Icons.skip_next,
            size: 40,
            color: musicProvider.currentIndex < musicProvider.songs.length - 1
                ? DraculaTheme.purple
                : DraculaTheme.comment,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }
}
