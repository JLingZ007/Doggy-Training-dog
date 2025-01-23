import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TrainingDetailPage extends StatefulWidget {
  final String trainingName;
  final String description;
  final String videoUrl;
  final List<String> tricks;

  const TrainingDetailPage({
    Key? key,
    required this.trainingName,
    required this.description,
    required this.videoUrl,
    required this.tricks,
  }) : super(key: key);

  @override
  State<TrainingDetailPage> createState() => _TrainingDetailPageState();
}

class _TrainingDetailPageState extends State<TrainingDetailPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trainingName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_controller.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              child: Text(_controller.value.isPlaying ? 'Pause' : 'Play'),
            ),
            const SizedBox(height: 20),
            Text(
              widget.description,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...widget.tricks.map((trick) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('- $trick'),
                )),
          ],
        ),
      ),
    );
  }
}
