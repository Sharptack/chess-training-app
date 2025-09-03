import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerView extends StatefulWidget {
  final String url;
  final VoidCallback? onStarted;
  final VoidCallback? onCompleted;

  const VideoPlayerView({
    super.key,
    required this.url,
    this.onStarted,
    this.onCompleted,
  });

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _started = false;

  @override
  void initState() {
    super.initState();

    // 👇 Branch between network and asset
    if (widget.url.startsWith('http')) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    } else {
      _videoController = VideoPlayerController.asset(widget.url);
    }

    _videoController.initialize().then((_) {
      setState(() {});
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
      );
    });

    _videoController.addListener(_handleVideoEvents);
  }

  void _handleVideoEvents() {
    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

    if (!_started && position > const Duration(seconds: 2)) {
      _started = true;
      widget.onStarted?.call();
    }

    if (duration.inSeconds > 0 &&
        position.inSeconds >= (duration.inSeconds * 0.9)) {
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_handleVideoEvents);
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null &&
        _videoController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
