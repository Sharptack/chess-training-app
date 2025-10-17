// lib/features/lesson/pages/lesson_page.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

import '../../../core/utils/responsive_utils.dart';
import '../../../data/models/video_item.dart';
import '../../../data/models/progress.dart';
import '../../../state/providers.dart';

/// Top-level page: fetches a lesson video by levelId, then shows player + progress.
class LessonPage extends ConsumerWidget {
  final String levelId;
  const LessonPage({Key? key, required this.levelId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoAsync = ref.watch(lessonByIdProvider(levelId));

    return videoAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Scaffold(
        body: Center(child: Text('Error loading lesson: $err')),
      ),
      data: (VideoItem video) {
        // Create callbacks here (we have `ref`), pass them down.
        return LessonScreen(
          levelId: levelId,
          video: video,
          onStart: () => markLessonStarted(ref, levelId, video.id),
          onComplete: () => markLessonCompleted(ref, levelId, video.id),
        );
      },
    );
  }
}

/// Stateless container for player + progress.
/// Keeps player stable while only ProgressSection rebuilds.
class LessonScreen extends StatelessWidget {
  final String levelId;
  final VideoItem video;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const LessonScreen({
    Key? key,
    required this.levelId,
    required this.video,
    required this.onStart,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(video.title)),
      body: Column(
        children: [
          // Player takes most space
          Expanded(
            child: LessonPlayer(
              video: video,
              onStart: onStart,
              onComplete: onComplete,
            ),
          ),
          // Reactive progress widget
          Builder(
            builder: (context) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getHorizontalPadding(context),
                vertical: ResponsiveUtils.getVerticalPadding(context) * 0.5,
              ),
              child: ProgressSection(levelId: levelId, videoId: video.id),
            ),
          ),
        ],
      ),
    );
  }
}

/// Video player widget that initializes once and calls callbacks on events.
class LessonPlayer extends StatefulWidget {
  final VideoItem video;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const LessonPlayer({
    Key? key,
    required this.video,
    required this.onStart,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends State<LessonPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  String? _initError;
  bool _started = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.video.url.trim();
    debugPrint('[LessonPlayer] init url="$url"');

    try {
      _videoController = url.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(url))
          : VideoPlayerController.asset(url);

      _videoController.addListener(_handleVideoEvents);

      // Add timeout for network videos to prevent hanging
      await _videoController.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Video failed to load within 30 seconds. Please check your internet connection.');
        },
      );

      if (_videoController.value.hasError) {
        _initError = _videoController.value.errorDescription ?? 'Unknown player error';
      } else {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: false,
          placeholder: widget.video.thumbnail != null
              ? Image.network(widget.video.thumbnail!, fit: BoxFit.cover)
              : const ColoredBox(color: Colors.black),
        );
      }
    } on TimeoutException catch (e) {
      _initError = e.message ?? 'Video loading timeout';
      debugPrint('[LessonPlayer] Timeout: ${e.message}');
    } catch (e, st) {
      _initError = e.toString();
      debugPrintStack(stackTrace: st);
    }

    if (mounted) setState(() {});
  }

  void _handleVideoEvents() {
    final v = _videoController.value;

    if (v.hasError) {
      if (_initError != v.errorDescription) {
        _initError = v.errorDescription ?? 'Player runtime error';
        if (mounted) setState(() {});
      }
      return;
    }

    final pos = v.position;
    final dur = v.duration;

    if (!_started && pos > const Duration(seconds: 2)) {
      _started = true;
      widget.onStart();
    }

    if (!_completed && dur.inSeconds > 0 && pos.inSeconds >= (dur.inSeconds * 0.9)) {
      _completed = true;
      widget.onComplete();
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
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '❌ Video failed to load:\n$_initError\n\nURL: ${widget.video.url}',
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
      );
    }

    if (_chewieController == null || !_videoController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final aspect = _videoController.value.aspectRatio > 0
        ? _videoController.value.aspectRatio
        : (16 / 9);

    return AspectRatio(
      aspectRatio: aspect,
      child: Chewie(controller: _chewieController!),
    );
  }
}

/// Shows progress and dev controls with better error handling
/// Only this widget rebuilds when progress changes.
class ProgressSection extends ConsumerWidget {
  final String levelId;
  final String videoId;

  const ProgressSection({Key? key, required this.levelId, required this.videoId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressKey = '${levelId}_$videoId';

    final async = ref.watch(lessonProgressProvider(progressKey));

    return async.when(
      loading: () {
        return const SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      error: (e, st) {
        return SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading progress: $e',
                style: TextStyle(color: Colors.red),
                softWrap: true,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Key: $progressKey',
                style: TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
      data: (Progress p) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.completed ? '✅ Completed' : (p.started ? '⏳ In Progress' : '▶️ Not Started'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            // Debug controls
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              // Wrap buttons to prevent overflow
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => markLessonStarted(ref, levelId, videoId),
                    child: const Text('Start'),
                  ),
                  ElevatedButton(
                    onPressed: () => markLessonCompleted(ref, levelId, videoId),
                    child: const Text('Complete'),
                  ),
                  ElevatedButton(
                    onPressed: () => resetLesson(ref, levelId, videoId),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}