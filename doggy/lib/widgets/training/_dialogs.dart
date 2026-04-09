import 'package:flutter/material.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kBgColor      = Color(0xFFF7EFE7);
const _kSurface      = Color(0xFFEFE2D3);
const _kFieldCream   = Color(0xFFEAD8C8);
const _kLightPaw     = Color(0xFFE8D5C0);
const _kPrimaryBrown = Color(0xFFB08968);
const _kDarkBrown    = Color(0xFF6D4C41);
const _kCancelColor  = Color(0xFF7C5959);
const _kSuccessGreen = Color(0xFF4C9A5C);
const _kSuccessBg    = Color(0xFFEDF6EE);
const _kSuccessBorder= Color(0xFFC3E6CB);

// ─── 1. Need Dog Dialog ───────────────────────────────────────────────────────
Future<void> showNeedDogDialog(
    BuildContext context, VoidCallback onGoSelectDog) async {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kLightPaw),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kSurface,
                shape: BoxShape.circle,
                border: Border.all(color: _kLightPaw),
              ),
              child: const Icon(Icons.pets_rounded,
                  size: 28, color: _kPrimaryBrown),
            ),
            const SizedBox(height: 16),
            // Title
            const Text(
              'เลือกสุนัขก่อนเริ่มฝึก',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kDarkBrown,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            // Body
            const Text(
              'โปรดเลือกสุนัขจากหน้า "ข้อมูลสุนัขของคุณ"\nก่อน แล้วกลับมาที่บทเรียนนี้',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _kPrimaryBrown,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onGoSelectDog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kDarkBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: const Text('ไปตั้งค่าสุนัข'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: _kPrimaryBrown,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: const Text('ปิด'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── 2. Confirm Step Done Sheet ───────────────────────────────────────────────
Future<bool?> showConfirmStepDoneSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (_) => _ConfirmStepSheet(context: context),
  );
}

class _ConfirmStepSheet extends StatefulWidget {
  final BuildContext context;
  const _ConfirmStepSheet({required this.context});

  @override
  State<_ConfirmStepSheet> createState() => _ConfirmStepSheetState();
}

class _ConfirmStepSheetState extends State<_ConfirmStepSheet> {
  bool _c1 = false;
  bool _c2 = false;

  @override
  Widget build(BuildContext context) {
    final canConfirm = _c1 && _c2;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Handle ──────────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kLightPaw,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // ── Icon ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kSuccessBg,
              shape: BoxShape.circle,
              border: Border.all(color: _kSuccessBorder),
            ),
            child: const Icon(Icons.fact_check_rounded,
                size: 26, color: _kSuccessGreen),
          ),
          const SizedBox(height: 14),

          // ── Title ─────────────────────────────────────────────────────────
          const Text(
            'ยืนยันความสำเร็จของขั้นตอนนี้',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kDarkBrown,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ตรวจสอบให้ครบทั้ง 2 ข้อก่อนกดยืนยัน',
            style: TextStyle(
              fontSize: 13,
              color: _kPrimaryBrown,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // ── Checklist ────────────────────────────────────────────────────
          _CheckItem(
            value: _c1,
            label: 'สุนัขทำได้ตามสัญญาณ 3 ครั้งติด',
            onChanged: (v) => setState(() => _c1 = v ?? false),
          ),
          const SizedBox(height: 10),
          _CheckItem(
            value: _c2,
            label: 'ไม่มีอาการเครียด/ลังเลชัดเจน',
            onChanged: (v) => setState(() => _c2 = v ?? false),
          ),

          const SizedBox(height: 24),

          // ── Confirm Button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: canConfirm
                    ? () => Navigator.pop(context, true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canConfirm ? _kSuccessGreen : _kFieldCream,
                  foregroundColor:
                      canConfirm ? Colors.white : _kPrimaryBrown,
                  disabledBackgroundColor: _kFieldCream,
                  disabledForegroundColor: _kPrimaryBrown,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canConfirm
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('ยืนยันสำเร็จ'),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _kPrimaryBrown,
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: const Text('ยังไม่พร้อม'),
          ),
        ],
      ),
    );
  }
}

// ─── Checklist Item ───────────────────────────────────────────────────────────
class _CheckItem extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;
  const _CheckItem(
      {required this.value,
      required this.label,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: value ? _kSuccessBg : _kBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? _kSuccessBorder : _kLightPaw,
            width: value ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? _kSuccessGreen : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: value ? _kSuccessGreen : _kLightPaw,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value ? const Color(0xFF2D6A3F) : _kDarkBrown,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 3. Watch Intro Dialog ────────────────────────────────────────────────────
Future<void> showWatchIntroDialog(
    BuildContext context, VoidCallback onScrollToVideo) async {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kLightPaw),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFDEA0)),
              ),
              child: const Icon(Icons.play_circle_outline_rounded,
                  size: 28, color: Color(0xFFB07D00)),
            ),
            const SizedBox(height: 16),
            // Title
            const Text(
              'ดูวิดีโอแนะนำก่อนเริ่ม',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kDarkBrown,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            // Body
            const Text(
              'เพื่อความเข้าใจที่ถูกต้อง กรุณาดูวิดีโอ\nแนะนำสั้น ๆ ก่อนเริ่มขั้นตอนที่ 1',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _kPrimaryBrown,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            // Go watch button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onScrollToVideo();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kDarkBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('ไปดูวิดีโอ'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: _kPrimaryBrown,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: const Text('ปิด'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}