import 'package:flutter/material.dart';

class NeedDogCallout extends StatelessWidget {
  final VoidCallback onSelectDog;
  const NeedDogCallout({super.key, required this.onSelectDog});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEEBA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pets_outlined),
          const SizedBox(width: 8),
          const Expanded(
              child: Text('ยังไม่ได้เลือกสุนัข • จะไม่บันทึกความคืบหน้า')),
          FilledButton(onPressed: onSelectDog, child: const Text('เลือกสุนัข')),
        ],
      ),
    );
  }
}
