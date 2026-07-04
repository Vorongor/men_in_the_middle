import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../utils/app_logger.dart';

/// Looping muted video background with a static image fallback.
///
/// Falls back to [fallback] when media_kit is unavailable (e.g. widget tests,
/// platforms without the native libs) or the asset fails to open.
class VideoBg extends StatefulWidget {
  const VideoBg({super.key, required this.fallback});

  final String fallback;

  @override
  State<VideoBg> createState() => _VideoBgState();
}

class _VideoBgState extends State<VideoBg> {
  static final _log = AppLogger.of('VideoBg');

  Player? _player;
  VideoController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    try {
      final player = Player();
      _player = player;
      _controller = VideoController(player);
      unawaited(
        player.open(Media('asset:///assets/media/matrix_bg.mp4')).then((_) async {
          await player.setPlaylistMode(PlaylistMode.loop);
          await player.setVolume(0);
          if (mounted) setState(() => _ready = true);
        }).catchError((Object e) {
          _log.warning('Failed to open ${widget.fallback}\'s video source', e);
          if (mounted) setState(() => _failed = true);
        }),
      );
    } catch (e) {
      _log.warning('Failed to initialize video player, falling back to ${widget.fallback}', e);
      _failed = true;
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed || !_ready || controller == null) {
      return Image.asset(widget.fallback, fit: BoxFit.cover);
    }
    return Video(
      controller: controller,
      fit: BoxFit.cover,
      controls: (state) => const SizedBox.shrink(),
    );
  }
}
