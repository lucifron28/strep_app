import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strep_app/widgets/queue_modal.dart';
import '../providers/music_provider.dart';
import '../services/audio_player_service.dart';
import '../theme/dracula_theme.dart';
import '../widgets/song_thumbnail.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: DraculaTheme.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Now Playing',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DraculaTheme.currentLine.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
              onPressed: () => Navigator.of(context).pop(),
              color: DraculaTheme.purple,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.queue_music, color: DraculaTheme.purple),
              tooltip: 'Show Queue',
              onPressed: () {
                final musicProvider = Provider.of<MusicProvider>(
                  context,
                  listen: false,
                );
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => QueueModal(
                    queue: musicProvider.queue,
                    currentSong: musicProvider.currentSong,
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<MusicProvider>(
          builder: (context, musicProvider, child) {
            final currentSong = musicProvider.currentSong;

            if (currentSong == null) {
              return const Center(child: Text('No song selected'));
            }

            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    DraculaTheme.purple.withValues(alpha: 0.1),
                    DraculaTheme.background.withValues(alpha: 0.95),
                  ],
                  center: Alignment.center,
                  radius: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Spacer(),

                    // Enhanced Album Art
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: DraculaTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: DraculaTheme.purple.withValues(alpha: 0.4),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: DraculaTheme.pink.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 8),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: DraculaTheme.background,
                        ),
                        child: SongThumbnail(
                          song: currentSong,
                          size: 300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Song Info
                    Text(
                      currentSong.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: DraculaTheme.foreground,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      currentSong.artist,
                      style: const TextStyle(
                        fontSize: 18,
                        color: DraculaTheme.purple,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      currentSong.album,
                      style: const TextStyle(
                        fontSize: 16,
                        color: DraculaTheme.cyan,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),

                    // Progress Bar
                    _buildProgressBar(musicProvider),

                    const SizedBox(height: 5),

                    // Control Buttons
                    _buildControlButtons(musicProvider),

                    const Spacer(),
                  ],
                ),
              ),
            );
          },
        ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: DraculaTheme.purple,
                      inactiveTrackColor: DraculaTheme.currentLine.withValues(
                        alpha: 0.4,
                      ),
                      thumbColor: DraculaTheme.pink,
                      overlayColor: DraculaTheme.purple.withValues(alpha: 0.1),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      trackShape: const RoundedRectSliderTrackShape(),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: DraculaTheme.background.withValues(
                              alpha: 0.3,
                            ),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Slider(
                        value: duration.inMilliseconds > 0
                            ? (position.inMilliseconds /
                                      duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                            : 0.0,
                        onChanged: (value) {
                          if (duration.inMilliseconds > 0) {
                            final newPosition = Duration(
                              milliseconds: (duration.inMilliseconds * value)
                                  .round(),
                            );
                            musicProvider.seek(newPosition);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DraculaTheme.currentLine.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDuration(position),
                          style: const TextStyle(
                            color: DraculaTheme.foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DraculaTheme.currentLine.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            color: DraculaTheme.foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
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
        Container(
          decoration: BoxDecoration(
            color: DraculaTheme.currentLine.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: DraculaTheme.background.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: musicProvider.currentIndex > 0
                ? () => musicProvider.skipToPrevious()
                : null,
            icon: Icon(
              Icons.skip_previous_rounded,
              size: 36,
              color: musicProvider.currentIndex > 0
                  ? DraculaTheme.purple
                  : DraculaTheme.comment,
            ),
          ),
        ),

        // Play/Pause
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: DraculaTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: DraculaTheme.purple.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: DraculaTheme.pink.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 8),
                spreadRadius: -5,
              ),
            ],
          ),
          child: StreamBuilder<PlayerState>(
            stream: musicProvider.audioService.playerStateStream,
            builder: (context, snapshot) {
              final currentPlayerState =
                  snapshot.data ?? musicProvider.playerState;
              return IconButton(
                onPressed: () => musicProvider.playPause(),
                icon: Icon(
                  currentPlayerState == PlayerState.playing
                      ? Icons.pause_rounded
                      : currentPlayerState == PlayerState.loading
                      ? Icons.hourglass_empty_rounded
                      : Icons.play_arrow_rounded,
                  size: 42,
                  color: DraculaTheme.background,
                ),
              );
            },
          ),
        ),

        // Next
        Container(
          decoration: BoxDecoration(
            color: DraculaTheme.currentLine.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: DraculaTheme.background.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed:
                musicProvider.currentIndex < musicProvider.songs.length - 1
                ? () => musicProvider.skipToNext()
                : null,
            icon: Icon(
              Icons.skip_next_rounded,
              size: 36,
              color: musicProvider.currentIndex < musicProvider.songs.length - 1
                  ? DraculaTheme.purple
                  : DraculaTheme.comment,
            ),
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
