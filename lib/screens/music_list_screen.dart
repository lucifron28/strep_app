import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/dracula_theme.dart';
import '../services/audio_player_service.dart';
import '../widgets/strep_icon.dart';
import '../widgets/song_options_bottom_sheet.dart';
import 'now_playing_screen.dart';

class MusicListScreen extends StatelessWidget {
  const MusicListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            StrepIcon(
              size: 32,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            const Text(
              'Strep',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MusicProvider>().loadMusic();
            },
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, musicProvider, child) {
          if (musicProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: DraculaTheme.purple),
                  SizedBox(height: 16),
                  Text('Loading music files...'),
                ],
              ),
            );
          }

          if (musicProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: DraculaTheme.red,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      musicProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      musicProvider.clearError();
                      musicProvider.loadMusic();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (musicProvider.songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StrepIcon(
                    size: 80,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Music Found',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Tap the refresh button to browse for MP3 files on your device',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => musicProvider.loadMusic(),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Browse Files'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Song count header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${musicProvider.songs.length} songs',
                  style: TextStyle(
                    color: DraculaTheme.comment,
                    fontSize: 16,
                  ),
                ),
              ),
              // Song list
              Expanded(
                child: ListView.builder(
                  itemCount: musicProvider.songs.length,
                  itemBuilder: (context, index) {
                    final song = musicProvider.songs[index];
                    final isCurrentSong = musicProvider.currentSong == song;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isCurrentSong ? DraculaTheme.purple : DraculaTheme.selection,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: StreamBuilder<PlayerState>(
                            stream: musicProvider.audioService.playerStateStream,
                            builder: (context, snapshot) {
                              final currentPlayerState = snapshot.data ?? musicProvider.playerState;
                              return isCurrentSong && currentPlayerState == PlayerState.playing
                                  ? Icon(
                                      Icons.pause,
                                      color: DraculaTheme.background,
                                      size: 28,
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: StrepIcon(
                                        size: 40,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    );
                            },
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentSong ? DraculaTheme.purple : DraculaTheme.foreground,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          style: TextStyle(
                            color: DraculaTheme.comment,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: DraculaTheme.comment,
                          ),
                          onPressed: () {
                            _showSongOptions(context, song, musicProvider);
                          },
                        ),
                        selected: isCurrentSong,
                        onTap: () {
                          musicProvider.playSong(song);
                        },
                      ),
                    );
                  },
                ),
              ),
              // Mini player (if song is playing)
              if (musicProvider.currentSong != null)
                _buildMiniPlayer(context, musicProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, MusicProvider musicProvider) {
    return Container(
      decoration: BoxDecoration(
        color: DraculaTheme.currentLine,
        border: Border(
          top: BorderSide(
            color: DraculaTheme.selection,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: StrepIcon(
          size: 48,
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(
          musicProvider.currentSong!.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          musicProvider.currentSong!.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: DraculaTheme.comment),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<PlayerState>(
              stream: musicProvider.audioService.playerStateStream,
              builder: (context, snapshot) {
                final currentPlayerState = snapshot.data ?? musicProvider.playerState;
                return IconButton(
                  icon: Icon(
                    currentPlayerState == PlayerState.playing
                        ? Icons.pause
                        : currentPlayerState == PlayerState.loading
                            ? Icons.hourglass_empty
                            : Icons.play_arrow,
                    color: DraculaTheme.purple,
                  ),
                  onPressed: () => musicProvider.playPause(),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.skip_next,
                color: DraculaTheme.purple,
              ),
              onPressed: () => musicProvider.skipToNext(),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NowPlayingScreen(),
            ),
          );
        },
      ),
    );
  }

  void _showSongOptions(BuildContext context, song, MusicProvider musicProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SongOptionsBottomSheet(
        song: song,
        onEditSong: (updatedSong) {
          musicProvider.updateSongDetails(song, updatedSong);
        },
        onDeleteSong: (songToDelete) {
          musicProvider.deleteSong(songToDelete);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Removed "${songToDelete.title}" from library',
                style: TextStyle(color: DraculaTheme.background),
              ),
              backgroundColor: DraculaTheme.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }
}
