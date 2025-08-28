import 'package:flutter/material.dart';
import 'package:strep_app/models/song.dart';

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
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView.builder(
            controller: scrollController,
            itemCount: 20, // Example item count
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Song ${index + 1}'),
                leading: const Icon(Icons.music_note),
              );
            },
          ),
        );
      },
    );
  }
}