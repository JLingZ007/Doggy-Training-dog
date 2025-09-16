import 'package:flutter/material.dart';

class LessonMeta extends StatelessWidget {
  final String difficulty;
  final String durationMin;
  final String description;
  const LessonMeta({
    super.key,
    required this.difficulty,
    required this.durationMin,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ความยาก: $difficulty'),
              Text('ระยะเวลา: $durationMin นาที'),
            ],
          ),
          const SizedBox(height: 12),
          if (description.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EDE4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(description),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
