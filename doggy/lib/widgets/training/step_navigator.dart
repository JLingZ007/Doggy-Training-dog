import 'package:flutter/material.dart';
import '../../models/step_item.dart';

class StepNavigator extends StatelessWidget {
  final List<StepItem> steps;
  final Set<int> completed;
  final int currentStep;
  final bool introWatched;
  final VoidCallback onNeedWatchIntro;
  final VoidCallback onJumpToCurrent;
  final void Function(int stepIndex1) onTapLocked; // แสดง hint เมื่อล็อก

  const StepNavigator({
    super.key,
    required this.steps,
    required this.completed,
    required this.currentStep,
    required this.introWatched,
    required this.onNeedWatchIntro,
    required this.onJumpToCurrent,
    required this.onTapLocked,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: steps.map((s) {
          final isDone = completed.contains(s.index1Based);
          final isCur = currentStep == s.index1Based;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isCur,
              label: Text(isDone ? '${s.index1Based} ✓' : '${s.index1Based}'),
              onSelected: (_) {
                if (!introWatched) {
                  onNeedWatchIntro();
                  return;
                }
                if (isCur) {
                  onJumpToCurrent();
                } else {
                  onTapLocked(s.index1Based);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
