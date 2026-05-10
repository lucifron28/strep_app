import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/music_provider.dart';
import '../services/yt_service_explode.dart';
import '../theme/dracula_theme.dart';

enum YouTubeDialogState {
  idle,
  fetchingInfo,
  ready,
  downloading,
  completed,
  failed,
  cancelled,
}

class YouTubeDownloadDialog extends StatefulWidget {
  final ValueChanged<Song> onSongDownloaded;

  const YouTubeDownloadDialog({super.key, required this.onSongDownloaded});

  @override
  State<YouTubeDownloadDialog> createState() => _YouTubeDownloadDialogState();
}

class _YouTubeDownloadDialogState extends State<YouTubeDownloadDialog> {
  final TextEditingController _urlController = TextEditingController();
  final YouTubeDownloadService _downloadService = YouTubeDownloadService();

  YouTubeDialogState _state = YouTubeDialogState.idle;
  double _downloadProgress = 0.0;
  VideoInfo? _videoInfo;
  String? _message;
  DownloadCancellationToken? _activeToken;

  bool get _isBusy =>
      _state == YouTubeDialogState.fetchingInfo ||
      _state == YouTubeDialogState.downloading;

  @override
  void dispose() {
    _activeToken?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;

    setState(() {
      _urlController.text = text;
      _state = YouTubeDialogState.idle;
      _message = null;
      _videoInfo = null;
    });
  }

  Future<void> _getVideoInfo() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _state = YouTubeDialogState.failed;
        _message = 'Paste a YouTube video URL first.';
      });
      return;
    }

    _dismissKeyboard();
    setState(() {
      _state = YouTubeDialogState.fetchingInfo;
      _message = null;
      _videoInfo = null;
      _downloadProgress = 0.0;
    });

    final result = await _downloadService.getVideoInfoResult(url);
    if (!mounted) return;

    setState(() {
      if (result.info != null) {
        _videoInfo = result.info;
        _state = YouTubeDialogState.ready;
      } else {
        _state = YouTubeDialogState.failed;
        _message = result.message ?? 'Could not fetch video information.';
      }
    });
  }

  Future<void> _downloadAudio() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final token = _downloadService.createCancellationToken();
    _activeToken = token;
    setState(() {
      _state = YouTubeDialogState.downloading;
      _downloadProgress = 0.0;
      _message = null;
    });

    final result = await _downloadService.downloadYouTubeAudio(
      url,
      cancellationToken: token,
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress;
        });
      },
    );

    if (!mounted) return;
    _activeToken = null;

    if (result.song != null) {
      widget.onSongDownloaded(result.song!);
      setState(() {
        _state = YouTubeDialogState.completed;
        _downloadProgress = 1.0;
        _message = 'Download completed.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded: ${result.song!.title}',
            style: TextStyle(color: DraculaTheme.background),
          ),
          backgroundColor: DraculaTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _state = result.failureType == DownloadFailureType.cancelled
          ? YouTubeDialogState.cancelled
          : YouTubeDialogState.failed;
      _message = result.message ?? 'Download failed.';
    });
  }

  void _cancelDownload() {
    _activeToken?.cancel();
    setState(() {
      _state = YouTubeDialogState.cancelled;
      _message = 'Download cancelled.';
    });
  }

  Future<void> _startBackgroundDownload() async {
    final videoInfo = _videoInfo;
    if (videoInfo == null) return;

    final musicProvider = context.read<MusicProvider>();
    await musicProvider.downloadManager.startDownload(
      url: _urlController.text.trim(),
      title: videoInfo.title,
      artist: videoInfo.author,
      thumbnailUrl: videoInfo.thumbnailUrl,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Background download started: ${videoInfo.title}',
          style: TextStyle(color: DraculaTheme.background),
        ),
        backgroundColor: DraculaTheme.cyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetForAnotherDownload() {
    setState(() {
      _urlController.clear();
      _state = YouTubeDialogState.idle;
      _downloadProgress = 0.0;
      _videoInfo = null;
      _message = null;
      _activeToken = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DraculaTheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Download from YouTube',
        style: TextStyle(
          color: DraculaTheme.foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              enabled: _state != YouTubeDialogState.completed && !_isBusy,
              style: TextStyle(color: DraculaTheme.foreground),
              decoration: InputDecoration(
                hintText: 'Paste YouTube URL here...',
                hintStyle: TextStyle(color: DraculaTheme.comment),
                filled: true,
                fillColor: DraculaTheme.currentLine,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.link, color: DraculaTheme.purple),
                suffixIcon: IconButton(
                  icon: Icon(Icons.content_paste, color: DraculaTheme.cyan),
                  tooltip: 'Paste from clipboard',
                  onPressed: _isBusy ? null : _pasteFromClipboard,
                ),
              ),
              onSubmitted: _isBusy ? null : (_) => _getVideoInfo(),
            ),
            const SizedBox(height: 10),
            Text(
              'Only download content you own or have permission to download.',
              style: TextStyle(color: DraculaTheme.comment, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (_state != YouTubeDialogState.completed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _state == YouTubeDialogState.fetchingInfo
                      ? null
                      : _getVideoInfo,
                  icon: _state == YouTubeDialogState.fetchingInfo
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DraculaTheme.background,
                          ),
                        )
                      : const Icon(Icons.info_outline),
                  label: Text(
                    _state == YouTubeDialogState.fetchingInfo
                        ? 'Getting info...'
                        : 'Get Video Info',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DraculaTheme.purple,
                    foregroundColor: DraculaTheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              _StatusMessage(message: _message!, state: _state),
            ],
            if (_videoInfo != null) ...[
              const SizedBox(height: 16),
              _VideoInfoPreview(videoInfo: _videoInfo!),
              const SizedBox(height: 16),
              if (_state != YouTubeDialogState.completed) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _state == YouTubeDialogState.downloading
                        ? null
                        : _downloadAudio,
                    icon: _state == YouTubeDialogState.downloading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DraculaTheme.background,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      _state == YouTubeDialogState.downloading
                          ? 'Downloading...'
                          : _state == YouTubeDialogState.failed
                          ? 'Retry Download'
                          : 'Download Audio',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DraculaTheme.green,
                      foregroundColor: DraculaTheme.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _state == YouTubeDialogState.downloading
                        ? null
                        : _startBackgroundDownload,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Download in Background'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DraculaTheme.cyan,
                      side: BorderSide(color: DraculaTheme.cyan),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              if (_state == YouTubeDialogState.downloading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: DraculaTheme.currentLine,
                  valueColor: AlwaysStoppedAnimation<Color>(DraculaTheme.green),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: TextStyle(color: DraculaTheme.comment, fontSize: 12),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (_state == YouTubeDialogState.downloading)
          TextButton(
            onPressed: _cancelDownload,
            child: Text(
              'Cancel Download',
              style: TextStyle(color: DraculaTheme.red),
            ),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              _state == YouTubeDialogState.completed ? 'Close' : 'Cancel',
              style: TextStyle(color: DraculaTheme.comment),
            ),
          ),
        if (_state == YouTubeDialogState.completed)
          TextButton(
            onPressed: _resetForAnotherDownload,
            child: Text(
              'Download Another',
              style: TextStyle(color: DraculaTheme.purple),
            ),
          ),
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, required this.state});

  final String message;
  final YouTubeDialogState state;

  @override
  Widget build(BuildContext context) {
    final isSuccess = state == YouTubeDialogState.completed;
    final isCancelled = state == YouTubeDialogState.cancelled;
    final color = isSuccess
        ? DraculaTheme.green
        : isCancelled
        ? DraculaTheme.orange
        : DraculaTheme.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess
                ? Icons.check_circle_outline
                : isCancelled
                ? Icons.cancel_outlined
                : Icons.error_outline,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

class _VideoInfoPreview extends StatelessWidget {
  const _VideoInfoPreview({required this.videoInfo});

  final VideoInfo videoInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DraculaTheme.currentLine.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DraculaTheme.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            videoInfo.title,
            style: TextStyle(
              color: DraculaTheme.foreground,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            videoInfo.author,
            style: TextStyle(color: DraculaTheme.purple, fontSize: 14),
          ),
          if (videoInfo.duration != null) ...[
            const SizedBox(height: 4),
            Text(
              'Duration: ${_formatDuration(videoInfo.duration!)}',
              style: TextStyle(color: DraculaTheme.comment, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
