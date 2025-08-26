class Song {
  final String title;
  final String artist;
  final String album;
  final String path;
  final Duration? duration;
  final String? albumArt;

  Song({
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    this.duration,
    this.albumArt,
  });

  factory Song.fromPath(String path) {
    final filename = path.split('/').last;
    final title = filename.replaceAll(RegExp(r'\.[^.]*$'), '');
    
    return Song(
      title: title,
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      path: path,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() {
    return 'Song(title: $title, artist: $artist, path: $path)';
  }
}
