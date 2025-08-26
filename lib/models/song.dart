class Song {
  String title;
  String artist;
  String album;
  final String path;
  final Duration? duration;
  final String? albumArt;
  String? customThumbnail;

  Song({
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    this.duration,
    this.albumArt,
    this.customThumbnail,
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

  // Create a copy of the song with updated details
  Song copyWith({
    String? title,
    String? artist,
    String? album,
    String? path,
    Duration? duration,
    String? albumArt,
    String? customThumbnail,
  }) {
    return Song(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      customThumbnail: customThumbnail ?? this.customThumbnail,
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
