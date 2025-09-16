import 'package:flutter/material.dart';

class ToolQuickActions extends StatelessWidget {
  final bool showClicker;
  final bool showWhistle;
  final VoidCallback? onOpenClicker;
  final VoidCallback? onOpenWhistle;

  const ToolQuickActions({
    super.key,
    this.showClicker = false,
    this.showWhistle = false,
    this.onOpenClicker,
    this.onOpenWhistle,
  });

  @override
  Widget build(BuildContext context) {
    if (!showClicker && !showWhistle) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (showClicker)
          OutlinedButton.icon(
            onPressed: onOpenClicker,
            icon: const Icon(Icons.touch_app),
            label: const Text('เปิดคลิกเกอร์'),
          ),
        if (showWhistle)
          OutlinedButton.icon(
            onPressed: onOpenWhistle,
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('เปิดนกหวีด'),
          ),
      ],
    );
  }
}
