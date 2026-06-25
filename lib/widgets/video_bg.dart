import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBg extends StatefulWidget {
  const VideoBg({super.key, required this.fallback});

  final String fallback;

  @override
  State<VideoBg> createState() => _VideoBgState();
}

class _VideoBgState extends State<VideoBg> {
  late final VideoPlayerController _ctrl;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset('assets/media/matrix_bg.mp4');
    _ctrl
        .initialize()
        .then((_) {
          _ctrl.setLooping(true);
          _ctrl.setVolume(0);
          _ctrl.play();
          if (mounted) setState(() => _ready = true);
        })
        .catchError((_) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || !_ready) {
      return Image.asset(widget.fallback, fit: BoxFit.cover);
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _ctrl.value.size.width,
        height: _ctrl.value.size.height,
        child: VideoPlayer(_ctrl),
      ),
    );
  }
}
