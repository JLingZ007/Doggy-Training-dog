import 'package:flutter/material.dart';
import '../../models/step_item.dart';
import 'tool_quick_actions.dart';

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

class StepCard extends StatelessWidget {
  final StepItem item;
  final bool isCompleted;
  final bool isCurrent;
  final bool showInlineHint;
  final bool saving;
  final VoidCallback onStart;
  final VoidCallback onDone;
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
    final lower       = item.text.toLowerCase();
    final needsClicker = lower.contains('คลิกเกอร์') ||
        lower.contains('clicker') ||
        lower.contains('[clicker]');
    final needsWhistle = lower.contains('นกหวีด') ||
        lower.contains('whistle') ||
        lower.contains('[whistle]');
    final useInlineSound = onOpenClicker == null && onOpenWhistle == null;

    // ── State-based styling ──────────────────────────────────────────────────
    final CardStyle style = isCompleted
        ? CardStyle.completed
        : isCurrent
            ? CardStyle.current
            : CardStyle.locked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: style.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.borderColor, width: style.borderWidth),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: _kPrimaryBrown.withOpacity(0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Step image ────────────────────────────────────────────────────
          if (item.image.isNotEmpty || isCurrent || isCompleted)
            _StepImage(imageUrl: item.image, style: style),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Step number badge + title ──────────────────────────────
                Row(
                  children: [
                    _StepBadge(
                      number: item.index1Based,
                      style: style,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ขั้นตอนที่ ${item.index1Based}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: style.titleColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    // Completed tick
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kSuccessBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kSuccessBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 13, color: _kSuccessGreen),
                            SizedBox(width: 4),
                            Text(
                              'สำเร็จแล้ว',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kSuccessGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Current indicator
                    if (isCurrent && !isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kDarkBrown,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '● ขั้นตอนนี้',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Step text ─────────────────────────────────────────────
                Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: style.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // ── Tool quick actions ────────────────────────────────────
                if (needsClicker || needsWhistle) ...[
                  const SizedBox(height: 12),
                  if (useInlineSound)
                    ToolQuickActions(
                      showClicker: needsClicker,
                      showWhistle: needsWhistle,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (needsClicker)
                          _ToolChip(
                            icon: Icons.touch_app_rounded,
                            label: 'คลิกเกอร์',
                            onTap: onOpenClicker!,
                          ),
                        if (needsWhistle)
                          _ToolChip(
                            icon: Icons.campaign_rounded,
                            label: 'นกหวีด',
                            onTap: onOpenWhistle!,
                          ),
                      ],
                    ),
                ],

                const SizedBox(height: 14),

                // ── Divider ───────────────────────────────────────────────
                if (!isCompleted)
                  Divider(color: style.borderColor, thickness: 1, height: 1),

                if (!isCompleted) const SizedBox(height: 14),

                // ── Action button row ────────────────────────────────────
                if (!isCompleted)
                  _ActionRow(
                    isCurrent: isCurrent,
                    saving: saving,
                    onStart: onStart,
                    onDone: onDone,
                  ),

                // ── Inline hint ───────────────────────────────────────────
                if (showInlineHint && !isCurrent && !isCompleted) ...[
                  const SizedBox(height: 12),
                  _InlineHint(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Style Data ──────────────────────────────────────────────────────────
enum CardStyle { completed, current, locked }

extension CardStyleX on CardStyle {
  Color get bgColor {
    switch (this) {
      case CardStyle.completed: return _kSuccessBg;
      case CardStyle.current:   return Colors.white;
      case CardStyle.locked:    return _kBgColor;
    }
  }

  Color get borderColor {
    switch (this) {
      case CardStyle.completed: return _kSuccessBorder;
      case CardStyle.current:   return _kPrimaryBrown;
      case CardStyle.locked:    return _kLightPaw;
    }
  }

  double get borderWidth {
    switch (this) {
      case CardStyle.current:   return 1.5;
      default:                  return 1.0;
    }
  }

  Color get titleColor {
    switch (this) {
      case CardStyle.completed: return const Color(0xFF2D6A3F);
      case CardStyle.current:   return _kDarkBrown;
      case CardStyle.locked:    return _kPrimaryBrown;
    }
  }

  Color get textColor {
    switch (this) {
      case CardStyle.completed: return const Color(0xFF3A7A4A);
      case CardStyle.current:   return _kDarkBrown;
      case CardStyle.locked:    return _kPrimaryBrown;
    }
  }

  Color get badgeColor {
    switch (this) {
      case CardStyle.completed: return _kSuccessBg;
      case CardStyle.current:   return _kDarkBrown;
      case CardStyle.locked:    return _kFieldCream;
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case CardStyle.completed: return _kSuccessGreen;
      case CardStyle.current:   return Colors.white;
      case CardStyle.locked:    return _kPrimaryBrown;
    }
  }
}

// ─── Step Image ───────────────────────────────────────────────────────────────
class _StepImage extends StatelessWidget {
  final String imageUrl;
  final CardStyle style;
  const _StepImage({required this.imageUrl, required this.style});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
      child: Stack(
        children: [
          imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 180,
                      color: _kFieldCream,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: _kPrimaryBrown,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                )
              : _fallback(),
          // Dimmed overlay for locked steps
          if (style == CardStyle.locked)
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.4)),
            ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
        height: 180,
        width: double.infinity,
        color: _kFieldCream,
        child: const Center(
          child: Icon(Icons.pets, size: 40, color: _kPrimaryBrown),
        ),
      );
}

// ─── Step Number Badge ────────────────────────────────────────────────────────
class _StepBadge extends StatelessWidget {
  final int number;
  final CardStyle style;
  const _StepBadge({required this.number, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: style.badgeColor,
        shape: BoxShape.circle,
        border: style == CardStyle.locked
            ? Border.all(color: _kLightPaw)
            : null,
      ),
      alignment: Alignment.center,
      child: style == CardStyle.completed
          ? const Icon(Icons.check_rounded, size: 16, color: _kSuccessGreen)
          : Text(
              '$number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: style.badgeTextColor,
              ),
            ),
    );
  }
}

// ─── Action Row ───────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final bool isCurrent;
  final bool saving;
  final VoidCallback onStart;
  final VoidCallback onDone;
  const _ActionRow({
    required this.isCurrent,
    required this.saving,
    required this.onStart,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      // ── Current: full-width "บันทึกการฝึก" ──
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: saving ? null : onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kDarkBrown,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _kLightPaw,
            disabledForegroundColor: _kPrimaryBrown,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: saving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kPrimaryBrown,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('กำลังบันทึก...'),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('บันทึกความสำเร็จ'),
                  ],
                ),
        ),
      );
    } else {
      // ── Locked: "รอขั้นตอนก่อนหน้า" pill ──
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _kFieldCream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kLightPaw),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 13, color: _kPrimaryBrown),
                SizedBox(width: 5),
                Text(
                  'รอขั้นตอนก่อนหน้า',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kPrimaryBrown,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}

// ─── Tool Chip ────────────────────────────────────────────────────────────────
class _ToolChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kLightPaw),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _kCancelColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kDarkBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Inline Hint ──────────────────────────────────────────────────────────────
class _InlineHint extends StatelessWidget {
  const _InlineHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFDEA0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: Color(0xFFB07D00)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'ทำทีละขั้นตามลำดับ กรุณาทำขั้นตอนปัจจุบันให้เสร็จก่อน',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7A5500),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}