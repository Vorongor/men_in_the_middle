import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoBg extends StatefulWidget {
  const VideoBg({super.key, required this.fallback});

  final String fallback;

  @override
  State<VideoBg> createState() => _VideoBgState();
}

class _VideoBgState extends State<VideoBg> {
  late final Player _player;
  late final VideoController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player
        .open(Media('asset:///assets/media/matrix_bg.mp4'))
        .then((_) async {
          await _player.setPlaylistMode(PlaylistMode.loop);
          await _player.setVolume(0);
          if (mounted) setState(() => _ready = true);
        })
        .catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || !_ready) {
      return Image.asset(widget.fallback, fit: BoxFit.cover);
    }
    return Video(
      controller: _controller,
      fit: BoxFit.cover,
      controls: NoVideoControls,
    );
  }
}
