import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../constants/app_colors.dart';

/// Shows the demo video for one sign, given its local Flutter asset
/// path (e.g. 'assets/videos/modyul_1/alpabeto/a.mp4'). Handles three
/// states:
///  - no path / asset not bundled yet -> static placeholder icon
///  - loading -> spinner
///  - ready -> autoplaying, looping video with playback controls
///
/// Renders itself as a Column (video area + control bar below), so
/// give it a bounded height or wrap it in Expanded/AspectRatio rather
/// than a fixed-height box sized for video-only content.
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

  // 0.5 = slow motion, 1.0 = normal, 1.5 = fast. Tapping an active
  // speed button again resets to 1.0 — see _setSpeed.
  double _speed = 1.0;

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
      _speed = 1.0;
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

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  void _stop() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.pause();
      controller.seekTo(Duration.zero);
    });
  }

  void _setSpeed(double target) {
    final controller = _controller;
    if (controller == null) return;
    // Tapping the already-active speed button resets to normal speed.
    final next = _speed == target ? 1.0 : target;
    controller.setPlaybackSpeed(next);
    setState(() => _speed = next);
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _togglePlay,
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
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white70,
                          size: 48,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              icon: Icons.replay,
              tooltip: 'Stop',
              onTap: _stop,
            ),
            const SizedBox(width: 10),
            _ControlButton(
              icon: controller.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              tooltip: controller.value.isPlaying ? 'Pause' : 'Play',
              onTap: _togglePlay,
              highlighted: true,
            ),
            const SizedBox(width: 10),
            _SpeedButton(
              label: '0.5x',
              active: _speed == 0.5,
              onTap: () => _setSpeed(0.5),
            ),
            const SizedBox(width: 10),
            _SpeedButton(
              label: '1.5x',
              active: _speed == 1.5,
              onTap: () => _setSpeed(1.5),
            ),
          ],
        ),
      ],
    );
  }
}

/// Round icon button used for Play/Pause/Stop in the video controls.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlighted;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted ? AppColors.accentYellow : Colors.white24,
          ),
          child: Icon(
            icon,
            size: 20,
            color: highlighted ? AppColors.primaryBlue : AppColors.textWhite,
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped "0.5x" / "1.5x" playback-speed toggle.
class _SpeedButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SpeedButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.accentYellow : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? AppColors.primaryBlue : AppColors.textWhite,
          ),
        ),
      ),
    );
  }
}
