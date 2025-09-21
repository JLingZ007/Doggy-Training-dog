import 'package:flutter/material.dart';

Future<void> showNeedDogDialog(
    BuildContext context, VoidCallback onGoSelectDog) async {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('เลือกสุนัขที่จะติดตาม'),
      content: const Text(
          'โปรดเลือกสุนัขจากหน้า “ข้อมูลสุนัขของคุณ” ก่อน แล้วกลับมาที่บทเรียนนี้'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
        ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onGoSelectDog();
            },
            child: const Text('ไปตั้งค่าสุนัข')),
      ],
    ),
  );
}

Future<bool?> showConfirmStepDoneSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      bool c1 = false, c2 = false;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ยืนยันความสำเร็จของขั้นตอนนี้',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            StatefulBuilder(builder: (ctx, setS) {
              return Column(children: [
                CheckboxListTile(
                    value: c1,
                    onChanged: (v) => setS(() => c1 = v ?? false),
                    title: const Text('สุนัขทำได้ตามสัญญาณ 3 ครั้งติด')),
                CheckboxListTile(
                    value: c2,
                    onChanged: (v) => setS(() => c2 = v ?? false),
                    title: const Text('ไม่มีอาการเครียด/ลังเลชัดเจน')),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed:
                        (c1 && c2) ? () => Navigator.pop(ctx, true) : null,
                    child: const Text('ยืนยันสำเร็จ')),
                const SizedBox(height: 12),
              ]);
            }),
          ],
        ),
      );
    },
  );
}

Future<void> showWatchIntroDialog(
    BuildContext context, VoidCallback onScrollToVideo) async {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('โปรดดูวิดีโอแนะนำก่อน'),
      content: const Text(
          'เพื่อความเข้าใจที่ถูกต้อง กรุณาดูวิดีโอแนะนำอย่างน้อยสั้น ๆ ก่อนเริ่มขั้นตอนที่ 1'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
        FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onScrollToVideo();
            },
            child: const Text('ไปดูวิดีโอ')),
      ],
    ),
  );
}
