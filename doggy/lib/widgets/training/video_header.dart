import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoHeader extends StatelessWidget {
  final YoutubePlayerController? controller;
  final String imageUrlFallback;
  const VideoHeader(
      {super.key, required this.controller, required this.imageUrlFallback});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: controller != null
            ? YoutubePlayer(controller: controller!)
            : (imageUrlFallback.isNotEmpty
                ? Image.network(
                    imageUrlFallback,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(height: 200, color: Colors.black12);
                    },
                    errorBuilder: (_, __, ___) => _grayHeader(),
                  )
                : _grayHeader()),
      ),
    );
  }

  Widget _grayHeader() => Container(
        height: 200,
        width: double.infinity,
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.ondemand_video, size: 56),
      );
}
