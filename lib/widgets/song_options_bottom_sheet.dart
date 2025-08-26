import 'package:flutter/material.dart';
import '../theme/dracula_theme.dart';
import '../models/song.dart';
import 'edit_song_dialog.dart';

class SongOptionsBottomSheet extends StatelessWidget {
  final Song song;
  final Function(Song) onEditSong;
  final Function(Song)? onDeleteSong;

  const SongOptionsBottomSheet({
    super.key,
    required this.song,
    required this.onEditSong,
    this.onDeleteSong,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DraculaTheme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        border: Border.all(
          color: DraculaTheme.selection,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DraculaTheme.comment,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: DraculaTheme.currentLine,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: DraculaTheme.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DraculaTheme.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: TextStyle(
                          fontSize: 14,
                          color: DraculaTheme.comment,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Options
          Column(
            children: [
              _buildOption(
                context,
                icon: Icons.edit,
                title: 'Edit Song Details',
                subtitle: 'Change title, artist, and album',
                onTap: () => _showEditDialog(context),
              ),
              _buildOption(
                context,
                icon: Icons.info_outline,
                title: 'Song Info',
                subtitle: 'View file path and details',
                onTap: () => _showSongInfo(context),
              ),
              _buildOption(
                context,
                icon: Icons.share,
                title: 'Share',
                subtitle: 'Share this song',
                onTap: () => _shareSong(context),
              ),
              _buildOption(
                context,
                icon: Icons.delete_outline,
                title: 'Remove from Library',
                subtitle: 'Remove this song from your library',
                onTap: () => _showDeleteConfirmation(context),
                isDestructive: true,
              ),
            ],
          ),
          
          // Bottom padding
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DraculaTheme.currentLine,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isDestructive ? DraculaTheme.red : DraculaTheme.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? DraculaTheme.red : DraculaTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: DraculaTheme.comment,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: DraculaTheme.comment,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    Navigator.of(context).pop(); // Close bottom sheet first
    
    showDialog(
      context: context,
      builder: (context) => EditSongDialog(
        song: song,
        onSave: onEditSong,
      ),
    );
  }

  void _showSongInfo(BuildContext context) {
    Navigator.of(context).pop(); // Close bottom sheet first
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DraculaTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Song Information',
          style: TextStyle(color: DraculaTheme.foreground),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Title', song.title),
            _buildInfoRow('Artist', song.artist),
            _buildInfoRow('Album', song.album),
            _buildInfoRow('File Path', song.path, isPath: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: DraculaTheme.purple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPath = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: DraculaTheme.comment,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: DraculaTheme.foreground,
            ),
            maxLines: isPath ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _shareSong(BuildContext context) {
    Navigator.of(context).pop(); // Close bottom sheet first
    
    // Show a simple message since we don't have sharing implemented
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sharing functionality coming soon!',
          style: TextStyle(color: DraculaTheme.background),
        ),
        backgroundColor: DraculaTheme.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    Navigator.of(context).pop(); // Close bottom sheet first
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DraculaTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: DraculaTheme.red, width: 1),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: DraculaTheme.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Remove Song',
              style: TextStyle(
                color: DraculaTheme.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove this song from your library?',
              style: TextStyle(
                color: DraculaTheme.foreground,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DraculaTheme.currentLine,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.music_note,
                    color: DraculaTheme.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: DraculaTheme.foreground,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist,
                          style: TextStyle(
                            color: DraculaTheme.comment,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will only remove the song from your app library. The audio file will remain on your device.',
              style: TextStyle(
                color: DraculaTheme.comment,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: DraculaTheme.comment),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onDeleteSong != null) {
                onDeleteSong!(song);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DraculaTheme.red,
              foregroundColor: DraculaTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Remove',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
