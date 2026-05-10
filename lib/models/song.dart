class Song {
  final String id;
  String title;
  String artist;
  String album;
  final String path;
  final Duration? duration;
  final String? albumArt;
  String? customThumbnail;
  final String source;
  final String? youtubeVideoId;
  final String? originalUrl;
  final DateTime dateAdded;

  Song({
    String? id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    this.duration,
    this.albumArt,
    this.customThumbnail,
    this.source = 'local',
    this.youtubeVideoId,
    this.originalUrl,
    DateTime? dateAdded,
  }) : id = id ?? _deriveId(path, source, youtubeVideoId),
       dateAdded = dateAdded ?? DateTime.now();

  factory Song.fromPath(String path) {
    final filename = path.split(RegExp(r'[\\/]')).last;
    final title = filename.replaceAll(RegExp(r'\.[^.]*$'), '');

    return Song(
      title: title,
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      path: path,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    final path = (json['path'] as String?) ?? '';
    final source = (json['source'] as String?) ?? 'local';
    final youtubeVideoId = json['youtubeVideoId'] as String?;

    return Song(
      id: json['id'] as String? ?? _deriveId(path, source, youtubeVideoId),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Unknown Title',
      artist: (json['artist'] as String?)?.trim().isNotEmpty == true
          ? json['artist'] as String
          : 'Unknown Artist',
      album: (json['album'] as String?)?.trim().isNotEmpty == true
          ? json['album'] as String
          : 'Unknown Album',
      path: path,
      duration: _durationFromJson(json),
      albumArt: json['albumArt'] as String?,
      customThumbnail: json['customThumbnail'] as String?,
      source: source,
      youtubeVideoId: youtubeVideoId,
      originalUrl: json['originalUrl'] as String?,
      dateAdded: _dateTimeFromJson(json['dateAdded']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'path': path,
      if (duration != null) 'durationMs': duration!.inMilliseconds,
      if (albumArt != null) 'albumArt': albumArt,
      if (customThumbnail != null) 'customThumbnail': customThumbnail,
      'source': source,
      if (youtubeVideoId != null) 'youtubeVideoId': youtubeVideoId,
      if (originalUrl != null) 'originalUrl': originalUrl,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  // Create a copy of the song with updated details
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? path,
    Duration? duration,
    String? albumArt,
    String? customThumbnail,
    String? source,
    String? youtubeVideoId,
    String? originalUrl,
    DateTime? dateAdded,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      customThumbnail: customThumbnail ?? this.customThumbnail,
      source: source ?? this.source,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      originalUrl: originalUrl ?? this.originalUrl,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  static String _deriveId(String path, String source, String? youtubeVideoId) {
    if (youtubeVideoId != null && youtubeVideoId.isNotEmpty) {
      return 'youtube:$youtubeVideoId';
    }
    final normalizedPath = path.trim().replaceAll('\\', '/').toLowerCase();
    return '$source:$normalizedPath';
  }

  static Duration? _durationFromJson(Map<String, dynamic> json) {
    final durationMs = json['durationMs'] ?? json['duration'];
    if (durationMs is int) {
      return Duration(milliseconds: durationMs);
    }
    if (durationMs is num) {
      return Duration(milliseconds: durationMs.round());
    }
    if (durationMs is String) {
      final parsed = int.tryParse(durationMs);
      if (parsed != null) {
        return Duration(milliseconds: parsed);
      }
    }
    return null;
  }

  static DateTime _dateTimeFromJson(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
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
