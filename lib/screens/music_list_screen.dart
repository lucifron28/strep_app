import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../services/download_manager_service.dart';
import '../theme/dracula_theme.dart';
import '../widgets/strep_icon.dart';
import '../widgets/song_options_bottom_sheet.dart';
import '../widgets/song_thumbnail.dart';
import '../widgets/youtube_download_dialog.dart';
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
    return Container(
      decoration: const BoxDecoration(
        gradient: DraculaTheme.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DraculaTheme.background.withValues(alpha: 0.95),
                  DraculaTheme.background.withValues(alpha: 0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: DraculaTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: DraculaTheme.purple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: StrepIcon(
                  size: 32,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Strep',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: DraculaTheme.currentLine.withValues(alpha: 0.7),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded, size: 28),
                onPressed: () => _importMusic(context),
                tooltip: 'Import Music Files',
                color: DraculaTheme.purple,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: DraculaTheme.currentLine.withValues(alpha: 0.7),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 28),
                onPressed: () {
                  context.read<MusicProvider>().loadMusic();
                },
                tooltip: 'Refresh Library',
                color: DraculaTheme.cyan,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: DraculaTheme.currentLine.withValues(alpha: 0.7),
              ),
              child: IconButton(
                icon: const Icon(Icons.video_library_rounded, size: 28),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => YouTubeDownloadDialog(
                      onSongDownloaded: (song) {
                        context.read<MusicProvider>().addYouTubeSong(song);
                      },
                    ),
                  );
                },
                tooltip: 'Download from YouTube',
                color: DraculaTheme.red,
              ),
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
      body: Consumer2<MusicProvider, DownloadManagerService>(
        builder: (context, musicProvider, downloadManager, child) {
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

          if (musicProvider.songs.isEmpty &&
              downloadManager.visibleDownloads.isEmpty) {
            return Container(
              decoration: const BoxDecoration(
                gradient: DraculaTheme.backgroundGradient,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: DraculaTheme.primaryGradient,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: DraculaTheme.currentLine.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: DraculaTheme.purple.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Welcome to Strep!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: DraculaTheme.purple,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Import MP3, M4A, AAC, WAV, FLAC, OGG, or WEBM files to start building your music library',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: DraculaTheme.comment,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: DraculaTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: DraculaTheme.purple.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => musicProvider.importMusic(),
                        icon: const Icon(Icons.add_rounded, size: 24),
                        label: const Text(
                          'Import Music Files',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: DraculaTheme.background,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
    ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, MusicProvider musicProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DraculaTheme.currentLine.withValues(alpha: 0.95),
            DraculaTheme.background.withValues(alpha: 0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(
            color: DraculaTheme.purple.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: DraculaTheme.background.withValues(alpha: 0.8),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
          BoxShadow(
            color: DraculaTheme.purple.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: SongThumbnail(
              song: musicProvider.currentSong!,
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
                  stream: musicProvider.positionStream.map((_) => musicProvider.playerState),
                  builder: (context, snapshot) {
                    final currentPlayerState = musicProvider.playerState;
                    return IconButton(
                      icon: Icon(
                        currentPlayerState.playing
                            ? Icons.pause
                            : currentPlayerState.processingState == ProcessingState.loading
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

  Future<void> _importMusic(BuildContext context) async {
    final musicProvider = context.read<MusicProvider>();
    final importedCount = await musicProvider.importMusic();
    if (!context.mounted) return;

    if (importedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported $importedCount song${importedCount == 1 ? '' : 's'}',
            style: TextStyle(color: DraculaTheme.background),
          ),
          backgroundColor: DraculaTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else if (musicProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            musicProvider.errorMessage!,
            style: TextStyle(color: DraculaTheme.background),
          ),
          backgroundColor: DraculaTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showSongOptions(
    BuildContext context,
    Song song,
    MusicProvider musicProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SongOptionsBottomSheet(
        song: song,
        onEditSong: (updatedSong) {
          musicProvider.updateSongDetails(song, updatedSong);
        },
        onChangeThumbnail: (song, thumbnailPath) {
          musicProvider.updateSongThumbnail(song, thumbnailPath);
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
        Consumer<DownloadManagerService>(
          builder: (context, downloadManager, child) {
            final activeDownloads = downloadManager.activeDownloads;
            return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            '${musicProvider.songs.length} songs${activeDownloads.isNotEmpty ? ', ${activeDownloads.length} downloading' : ''}',
            style: TextStyle(
              color: DraculaTheme.comment,
              fontSize: 16,
            ),
          ),
            );
          },
        ),
        // Song list (including downloading items)
        Expanded(
          child: Consumer<DownloadManagerService>(
            builder: (context, downloadManager, child) {
              final visibleDownloads = downloadManager.visibleDownloads;
              final totalItems =
                  musicProvider.songs.length + visibleDownloads.length;

              if (totalItems == 0) {
                return _buildEmptyTab(
                  icon: Icons.music_note,
                  title: 'No songs yet',
                  message:
                      'Import audio files or download permitted YouTube content.',
                );
              }

              return ListView.builder(
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  // Show downloading items first
                  if (index < visibleDownloads.length) {
                    final downloadItem = visibleDownloads[index];
                    return _buildDownloadTile(downloadItem, musicProvider);
                  }
                  
                  // Then show regular songs
                  final songIndex = index - visibleDownloads.length;
                  final song = musicProvider.songs[songIndex];
                  return _buildSongTile(song, musicProvider);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTab({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: DraculaTheme.comment, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: DraculaTheme.foreground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: DraculaTheme.comment),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumsTab(MusicProvider musicProvider) {
    final albumMap = <String, List<Song>>{};
    
    // Group songs by album
    for (final song in musicProvider.songs) {
      final albumName = song.album.isEmpty ? 'Unknown Album' : song.album;
      if (!albumMap.containsKey(albumName)) {
        albumMap[albumName] = [];
      }
      albumMap[albumName]!.add(song);
    }

    final albums = albumMap.keys.toList()..sort();

    if (albums.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.album,
        title: 'No albums yet',
        message: 'Imported songs with album metadata will appear here.',
      );
    }

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
                children: albumSongs
                    .map(
                      (song) => _buildSongTile(
                        song,
                        musicProvider,
                        padding: 32.0,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArtistsTab(MusicProvider musicProvider) {
    final artistMap = <String, List<Song>>{};
    
    // Group songs by artist
    for (final song in musicProvider.songs) {
      final artistName = song.artist.isEmpty ? 'Unknown Artist' : song.artist;
      if (!artistMap.containsKey(artistName)) {
        artistMap[artistName] = [];
      }
      artistMap[artistName]!.add(song);
    }

    final artists = artistMap.keys.toList()..sort();

    if (artists.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.person,
        title: 'No artists yet',
        message: 'Imported songs with artist metadata will appear here.',
      );
    }

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
                children: artistSongs
                    .map(
                      (song) => _buildSongTile(
                        song,
                        musicProvider,
                        padding: 32.0,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadTile(
    DownloadItem downloadItem,
    MusicProvider musicProvider, {
    double padding = 16.0,
  }) {
    final canCancel = downloadItem.status == DownloadStatus.queued ||
        downloadItem.status == DownloadStatus.downloading;
    final canRetry = downloadItem.status == DownloadStatus.failed ||
        downloadItem.status == DownloadStatus.cancelled;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DraculaTheme.cyan.withValues(alpha: 0.1),
            DraculaTheme.purple.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DraculaTheme.cyan.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DraculaTheme.cyan.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: DraculaTheme.cyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DraculaTheme.cyan.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.cloud_download,
                color: DraculaTheme.cyan,
                size: 24,
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: DraculaTheme.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(downloadItem.progress * 100).toInt()}%',
                    style: TextStyle(
                      color: DraculaTheme.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          downloadItem.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: DraculaTheme.cyan,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                downloadItem.artist,
                style: TextStyle(
                  color: DraculaTheme.comment,
                  fontSize: 14,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            LinearProgressIndicator(
              value: downloadItem.progress,
              backgroundColor: DraculaTheme.currentLine.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(DraculaTheme.cyan),
              minHeight: 4,
            ),
            const SizedBox(height: 4),
            Text(
              _downloadStatusText(downloadItem),
              style: TextStyle(
                color: DraculaTheme.cyan.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: DraculaTheme.currentLine.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              canRetry ? Icons.refresh : Icons.cancel,
              color: canRetry ? DraculaTheme.orange : DraculaTheme.red,
              size: 20,
            ),
            onPressed: () {
              if (canRetry) {
                musicProvider.downloadManager.retryDownload(downloadItem.id);
              } else if (canCancel) {
                musicProvider.downloadManager.cancelDownload(downloadItem.id);
              } else {
                musicProvider.downloadManager.removeDownload(downloadItem.id);
              }
            },
            tooltip: canRetry ? 'Retry Download' : 'Cancel Download',
          ),
        ),
        selected: false,
        selectedTileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: () {
          // Show download details or options
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_downloadStatusText(downloadItem)}: ${downloadItem.title}',
                style: TextStyle(color: DraculaTheme.background),
              ),
              backgroundColor: DraculaTheme.cyan,
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

  String _downloadStatusText(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.downloading:
        return 'Downloading ${(item.progress * 100).toInt()}%';
      case DownloadStatus.queued:
        return 'Queued for download';
      case DownloadStatus.failed:
        return item.errorMessage ?? 'Download failed';
      case DownloadStatus.cancelled:
        return 'Download cancelled';
      case DownloadStatus.completed:
        return 'Download completed';
    }
  }

  Widget _buildSongTile(
    Song song,
    MusicProvider musicProvider, {
    double padding = 16.0,
  }) {
    final isCurrentSong = musicProvider.currentSong == song;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding, vertical: 6),
      decoration: BoxDecoration(
        gradient: isCurrentSong 
          ? LinearGradient(
              colors: [
                DraculaTheme.purple.withValues(alpha: 0.1),
                DraculaTheme.pink.withValues(alpha: 0.05),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : null,
        color: isCurrentSong ? null : DraculaTheme.currentLine.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentSong 
            ? DraculaTheme.purple.withValues(alpha: 0.4)
            : DraculaTheme.comment.withValues(alpha: 0.1),
          width: isCurrentSong ? 2 : 1,
        ),
        boxShadow: isCurrentSong ? [
          BoxShadow(
            color: DraculaTheme.purple.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : [
          BoxShadow(
            color: DraculaTheme.background.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: StreamBuilder<PlayerState>(
          stream: musicProvider.positionStream.map((_) => musicProvider.playerState),
          builder: (context, snapshot) {
            final currentPlayerState = musicProvider.playerState;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isCurrentSong 
                      ? DraculaTheme.purple.withValues(alpha: 0.3)
                      : DraculaTheme.background.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SongThumbnail(
                song: song,
                size: 56,
                borderRadius: BorderRadius.circular(12),
                isCurrentSong: isCurrentSong,
                showPlayIcon: isCurrentSong && currentPlayerState.playing,
              ),
            );
          },
        ),
        title: Text(
          song.title,
          style: TextStyle(
            fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.w600,
            fontSize: 16,
            color: isCurrentSong ? DraculaTheme.purple : DraculaTheme.foreground,
            letterSpacing: 0.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            song.artist,
            style: TextStyle(
              color: isCurrentSong ? DraculaTheme.pink.withValues(alpha: 0.8) : DraculaTheme.comment,
              fontSize: 14,
              letterSpacing: 0.1,
            ),
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: DraculaTheme.currentLine.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isCurrentSong ? DraculaTheme.pink : DraculaTheme.comment,
              size: 20,
            ),
            onPressed: () {
              _showSongOptions(context, song, musicProvider);
            },
          ),
        ),
        selected: isCurrentSong,
        selectedTileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: () {
          if (isCurrentSong) {
            musicProvider.playPause();
          } else {
            musicProvider.playSong(song);
          }
        },
      ),
    );
  }
}
