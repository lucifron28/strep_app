import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/dracula_theme.dart';
import '../services/audio_player_service.dart';
import '../widgets/strep_icon.dart';
import '../widgets/song_options_bottom_sheet.dart';
import 'now_playing_screen.dart';

class MusicListScreen extends StatefulWidget {
  const MusicListScreen({super.key});

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: DraculaTheme.currentLine,
          border: Border(
            top: BorderSide(
              color: DraculaTheme.purple.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: DraculaTheme.background.withValues(alpha: 0.9),
              offset: const Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: DraculaTheme.purple,
          unselectedItemColor: DraculaTheme.comment,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note),
              label: 'All Songs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.album),
              label: 'Albums',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Artists',
            ),
          ],
        ),
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
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildAllSongsTab(musicProvider),
                    _buildAlbumsTab(musicProvider),
                    _buildArtistsTab(musicProvider),
                  ],
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
          bottom: BorderSide(
            color: DraculaTheme.selection,
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: DraculaTheme.background.withValues(alpha: 0.8),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
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
          // Additional separator line
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  DraculaTheme.purple.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
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
            }
          });
        },
      ),
    );
  }

  Widget _buildAllSongsTab(MusicProvider musicProvider) {
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
              return _buildSongTile(song, musicProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumsTab(MusicProvider musicProvider) {
    final albumMap = <String, List<dynamic>>{};
    
    // Group songs by album
    for (final song in musicProvider.songs) {
      final albumName = song.album.isEmpty ? 'Unknown Album' : song.album;
      if (!albumMap.containsKey(albumName)) {
        albumMap[albumName] = [];
      }
      albumMap[albumName]!.add(song);
    }

    final albums = albumMap.keys.toList()..sort();

    return Column(
      children: [
        // Album count header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            '${albums.length} albums',
            style: TextStyle(
              color: DraculaTheme.comment,
              fontSize: 16,
            ),
          ),
        ),
        // Album list
        Expanded(
          child: ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final albumName = albums[index];
              final albumSongs = albumMap[albumName]!;
              
              return ExpansionTile(
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: DraculaTheme.selection,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.album,
                    color: DraculaTheme.purple,
                    size: 28,
                  ),
                ),
                title: Text(
                  albumName,
                  style: TextStyle(
                    color: DraculaTheme.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${albumSongs.length} song${albumSongs.length != 1 ? 's' : ''}',
                  style: TextStyle(color: DraculaTheme.comment),
                ),
                iconColor: DraculaTheme.purple,
                collapsedIconColor: DraculaTheme.comment,
                children: albumSongs.map((song) => _buildSongTile(song, musicProvider, padding: 32.0)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArtistsTab(MusicProvider musicProvider) {
    final artistMap = <String, List<dynamic>>{};
    
    // Group songs by artist
    for (final song in musicProvider.songs) {
      final artistName = song.artist.isEmpty ? 'Unknown Artist' : song.artist;
      if (!artistMap.containsKey(artistName)) {
        artistMap[artistName] = [];
      }
      artistMap[artistName]!.add(song);
    }

    final artists = artistMap.keys.toList()..sort();

    return Column(
      children: [
        // Artist count header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            '${artists.length} artists',
            style: TextStyle(
              color: DraculaTheme.comment,
              fontSize: 16,
            ),
          ),
        ),
        // Artist list
        Expanded(
          child: ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artistName = artists[index];
              final artistSongs = artistMap[artistName]!;
              
              return ExpansionTile(
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: DraculaTheme.selection,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: DraculaTheme.purple,
                    size: 28,
                  ),
                ),
                title: Text(
                  artistName,
                  style: TextStyle(
                    color: DraculaTheme.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${artistSongs.length} song${artistSongs.length != 1 ? 's' : ''}',
                  style: TextStyle(color: DraculaTheme.comment),
                ),
                iconColor: DraculaTheme.purple,
                collapsedIconColor: DraculaTheme.comment,
                children: artistSongs.map((song) => _buildSongTile(song, musicProvider, padding: 32.0)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSongTile(dynamic song, MusicProvider musicProvider, {double padding = 16.0}) {
    final isCurrentSong = musicProvider.currentSong == song;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
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
  }
}
