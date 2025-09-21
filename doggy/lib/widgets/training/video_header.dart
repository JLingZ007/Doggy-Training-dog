import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoHeader extends StatelessWidget {
  final YoutubePlayerController? controller;
  final String imageUrlFallback;

  const VideoHeader({
    super.key,
    required this.controller,
    required this.imageUrlFallback,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlayer = controller != null;


    return AspectRatio(
      aspectRatio: 16 / 9,
      child: hasPlayer         
          ? YoutubePlayer(controller: controller!)

          : (imageUrlFallback.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrlFallback,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(color: Colors.black12);
                    },
                    errorBuilder: (_, __, ___) => _grayHeader(),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _grayHeader(),
                )),
    );
    // ^^^^^^ CODE CHANGE ^^^^^^
  }

  Widget _grayHeader() => Container(
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.ondemand_video, size: 56),
      );
}