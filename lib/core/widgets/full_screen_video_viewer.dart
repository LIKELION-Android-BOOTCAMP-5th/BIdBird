import 'package:bidbird/core/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';

/// 전체 화면 동영상 뷰어
class FullScreenVideoViewer extends StatelessWidget {
  final String videoUrl;

  const FullScreenVideoViewer({
    super.key,
    required this.videoUrl,
  });

  static void show(BuildContext context, String videoUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenVideoViewer(videoUrl: videoUrl),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: VideoPlayerWidget(
          videoPath: videoUrl,
          isNetworkUrl: true,
          autoPlay: true,
          showControls: true,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}