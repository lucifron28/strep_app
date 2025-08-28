import 'package:flutter/material.dart';
import 'package:strep_app/models/song.dart';
import 'package:strep_app/providers/music_provider.dart';
import 'package:provider/provider.dart';
import 'package:strep_app/theme/dracula_theme.dart';
import 'song_thumbnail.dart';

class QueueModal extends StatelessWidget {
  final List<Song> queue;
  final Song? currentSong;

  const QueueModal({
    super.key,
    required this.queue,
    this.currentSong,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: DraculaTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DraculaTheme.comment.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Queue',
                style: TextStyle(
                  color: DraculaTheme.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: queue.isEmpty
                    ? Center(
                        child: Text(
                          "Queue is empty",
                          style: TextStyle(color: DraculaTheme.comment),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: queue.length,
                        itemBuilder: (context, index) {
                          final song = queue[index];
                          final isCurrent = song == currentSong;
                          return ListTile(
                            leading: SongThumbnail(song: song, size: 40, borderRadius:BorderRadius.all(Radius.circular(8 ))),
                            title: Text(
                              song.title,
                              style: TextStyle(
                                color: isCurrent
                                    ? DraculaTheme.purple
                                    : DraculaTheme.foreground,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist,
                              style: TextStyle(
                                color: DraculaTheme.comment,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: isCurrent,
                            selectedTileColor:
                                DraculaTheme.purple.withValues(alpha: 0.08),
                            onTap: () {
                              Provider.of<MusicProvider>(context, listen: false)
                                  .playSongAt(index);
                              Navigator.pop(context);
                            },
                            trailing: IconButton(
                              icon: Icon(Icons.close,
                                  color: DraculaTheme.red.withValues(alpha: 0.7)),
                              tooltip: "Remove from queue",
                              onPressed: () {
                                Provider.of<MusicProvider>(context,
                                        listen: false)
                                    .removeFromQueue(song);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}