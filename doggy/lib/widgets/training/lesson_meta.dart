import 'package:flutter/material.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kSurface      = Color(0xFFEFE2D3);
const _kFieldCream   = Color(0xFFEAD8C8);
const _kLightPaw     = Color(0xFFE8D5C0);
const _kPrimaryBrown = Color(0xFFB08968);
const _kDarkBrown    = Color(0xFF6D4C41);
const _kCancelColor  = Color(0xFF7C5959);

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

  // Map difficulty text → icon + color
  _DifficultyStyle _diffStyle(String diff) {
    final d = diff.toLowerCase().trim();
    if (d.contains('ยาก') || d.contains('hard')) {
      return _DifficultyStyle(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFE07B39),
        bg: const Color(0xFFFFF1DC),
        border: const Color(0xFFFFDEA0),
      );
    } else if (d.contains('ปาน') || d.contains('medium') || d.contains('ปกติ')) {
      return _DifficultyStyle(
        icon: Icons.bolt_rounded,
        color: const Color(0xFFB07D00),
        bg: const Color(0xFFFFF8EC),
        border: const Color(0xFFFFE4A0),
      );
    } else {
      return _DifficultyStyle(
        icon: Icons.eco_rounded,
        color: const Color(0xFF4C9A5C),
        bg: const Color(0xFFEDF6EE),
        border: const Color(0xFFC3E6CB),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diff = _diffStyle(difficulty);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Meta chips row ─────────────────────────────────────────────
          Row(
            children: [
              // Difficulty chip
              _MetaChip(
                icon: diff.icon,
                iconColor: diff.color,
                bg: diff.bg,
                border: diff.border,
                label: 'ความยาก',
                value: difficulty,
                valueColor: diff.color,
              ),
              const SizedBox(width: 10),
              // Duration chip
              _MetaChip(
                icon: Icons.schedule_rounded,
                iconColor: _kPrimaryBrown,
                bg: _kFieldCream,
                border: _kLightPaw,
                label: 'ระยะเวลา',
                value: '$durationMin นาที',
                valueColor: _kDarkBrown,
              ),
            ],
          ),

          // ── Description ────────────────────────────────────────────────
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kLightPaw),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _kFieldCream,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 14,
                      color: _kCancelColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kDarkBrown,
                        height: 1.65,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Meta Chip ────────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final Color border;
  final String label;
  final String value;
  final Color valueColor;

  const _MetaChip({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.border,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: iconColor.withOpacity(0.75),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Difficulty Style Data ────────────────────────────────────────────────────
class _DifficultyStyle {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  const _DifficultyStyle({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
  });
}