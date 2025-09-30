import 'package:flutter/material.dart';
import '../../models/step_item.dart';
import 'tool_quick_actions.dart'; 

class StepCard extends StatelessWidget {
  final StepItem item;
  final bool isCompleted;
  final bool isCurrent;
  final bool showInlineHint;
  final bool saving;
  final VoidCallback onStart;
  final VoidCallback onDone;

  /// ถ้ามีการส่ง callback มา จะถือว่าใช้ "โหมดนำทางไปหน้าเครื่องมือ"
  /// ถ้าไม่ส่ง (null) จะใช้ ToolQuickActions เล่นเสียงในหน้านี้แทน (inline)
  final VoidCallback? onOpenClicker;
  final VoidCallback? onOpenWhistle;

  const StepCard({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.isCurrent,
    required this.showInlineHint,
    required this.saving,
    required this.onStart,
    required this.onDone,
    this.onOpenClicker,
    this.onOpenWhistle,
  });

  @override
  Widget build(BuildContext context) {
    // ===== ตรวจคีย์เวิร์ดจากข้อความ step (วิธีที่ 1) =====
    final lower = item.text.toLowerCase();
    final needsClicker = lower.contains('คลิกเกอร์') || lower.contains('clicker') || lower.contains('[clicker]');
    final needsWhistle = lower.contains('นกหวีด') || lower.contains('whistle') || lower.contains('[whistle]');

    // ถ้าไม่ส่ง callback มาเลย -> ใช้ inline sound
    final bool useInlineSound = onOpenClicker == null && onOpenWhistle == null;

    // เตรียมสีพื้น/ป้าย/ปุ่มตามสถานะ
    late final Color bg;
    late final String badge;
    late final Widget actionBtn;

    if (isCompleted) {
      bg = const Color(0xFFE5F6E8); // เขียวอ่อน
      badge = 'สำเร็จแล้ว ✓';
      actionBtn = ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5F6E8),
          foregroundColor: const Color(0xFF2E7D32),
          disabledBackgroundColor: const Color(0xFFE5F6E8),
          disabledForegroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        child: const Text('สำเร็จแล้ว', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (isCurrent) {
      bg = const Color(0xFFFFF9E6); // เหลืองพาสเทล
      badge = 'ขั้นตอนปัจจุบัน ⏳';
      actionBtn = ElevatedButton(
        onPressed: saving ? null : onDone,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA5D6A7), // เขียวพาสเทล
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          elevation: 0,
        ),
        child: Text(
          saving ? 'กำลังบันทึก...' : 'บันทึกการฝึก',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    } else {
      bg = const Color(0xFFE3F2FD); // ฟ้าอ่อน
      badge = 'รอคิว ▶️';
      actionBtn = ElevatedButton(
        onPressed: onStart,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF90CAF9),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          elevation: 0,
        ),
        child: const Text('เริ่มฝึก', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    // ==== UI จริง ====
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูป
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.image.isNotEmpty
                ? Image.network(
                    item.image,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgFallback(),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(height: 170, color: Colors.black12);
                    },
                  )
                : _imgFallback(),
          ),
          const SizedBox(height: 10),

          // หัวข้อ & เนื้อหา
          Text(
            'ขั้นตอนที่ ${item.index1Based}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(item.text, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 8),

          // ===== ปุ่มเครื่องมือ =====
          if (needsClicker || needsWhistle) ...[
            if (useInlineSound)
              // เล่นเสียงในหน้านี้เลย
              ToolQuickActions(
                showClicker: needsClicker,
                showWhistle: needsWhistle,
              )
            else
              // โหมดเดิม: นำทางไปหน้าเครื่องมือ (ยังรองรับเผื่อมีที่อื่นส่ง callback มา)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (needsClicker)
                    OutlinedButton.icon(
                      onPressed: onOpenClicker,
                      icon: const Icon(Icons.touch_app),
                      label: const Text('เปิดคลิกเกอร์'),
                    ),
                  if (needsWhistle)
                    OutlinedButton.icon(
                      onPressed: onOpenWhistle,
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('เปิดนกหวีด'),
                    ),
                ],
              ),
            const SizedBox(height: 8),
          ],

          // ป้ายสถานะ + ปุ่มหลัก
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              actionBtn,
            ],
          ),

          // Hint เมื่อติ๊กผิดลำดับ
          if (showInlineHint && !isCurrent && !isCompleted) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ทำทีละขั้น กรุณารอให้ถึง “ขั้นตอนที่กำลังทำ” ก่อน '
                      'คุณสามารถใช้ปุ่มด้านบนเพื่อไปยังขั้นตอนปัจจุบันได้ทันที',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- helper ภายใน widget ----
  Widget _imgFallback() => Container(
        height: 170,
        width: double.infinity,
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 48),
      );
}
