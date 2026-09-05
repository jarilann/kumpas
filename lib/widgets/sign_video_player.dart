import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../constants/app_colors.dart';

/// Shows the demo video for one sign, given its local Flutter asset
/// path (e.g. 'assets/videos/modyul_1/alpabeto/a.mp4'). Handles three
/// states:
///  - no path / asset not bundled yet -> static placeholder icon
///  - loading -> spinner
///  - ready -> tap-to-play video, looping
///
/// Used inside a fixed-height box (see LessonContentScreen), so it
/// always fills its parent rather than sizing itself to the video's
/// native aspect ratio.
///
/// NOTE: every path this widget is given must also be listed (or
/// covered by a folder entry) under pubspec.yaml's `assets:` — see
/// the `assets/videos/` entry. Bundling videos as assets means they
/// ship inside the app itself (no Firebase Storage / billing needed),
/// at the cost of increasing the app's download size as more videos
/// are added.
class SignVideoPlayer extends StatefulWidget {
  final String? assetPath;

  const SignVideoPlayer({super.key, required this.assetPath});

  @override
  State<SignVideoPlayer> createState() => _SignVideoPlayerState();
}

class _SignVideoPlayerState extends State<SignVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SignVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _disposeController();
      _load();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  Future<void> _load() async {
    final path = widget.assetPath;
    setState(() {
      _loading = true;
      _notFound = false;
    });

    if (path == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _notFound = true;
        });
      }
      return;
    }

    final controller = VideoPlayerController.asset(path);
    try {
      await controller.initialize();
      controller.setLooping(true);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      controller.play();
    } catch (_) {
      // Most commonly the asset isn't bundled yet (not listed under
      // pubspec.yaml's assets:, or the .mp4 file hasn't been added).
      controller.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _notFound = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.textWhite),
      );
    }

    if (_notFound || _controller == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, color: AppColors.textWhite, size: 48),
            SizedBox(height: 6),
            Text(
              'Wala pang video',
              style: TextStyle(color: AppColors.textWhiteMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final controller = _controller!;
    return GestureDetector(
      onTap: () {
        setState(() {
          controller.value.isPlaying ? controller.pause() : controller.play();
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(controller),
                if (!controller.value.isPlaying)
                  const Icon(Icons.play_circle_fill, color: Colors.white70, size: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
