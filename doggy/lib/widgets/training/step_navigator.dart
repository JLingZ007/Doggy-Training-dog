import 'package:flutter/material.dart';
import '../../models/step_item.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kFieldCream   = Color(0xFFEAD8C8);
const _kLightPaw     = Color(0xFFE8D5C0);
const _kPrimaryBrown = Color(0xFFB08968);
const _kDarkBrown    = Color(0xFF6D4C41);
const _kSuccessGreen = Color(0xFF4C9A5C);
const _kSuccessBg    = Color(0xFFEDF6EE);
const _kSuccessBorder= Color(0xFFC3E6CB);

class StepNavigator extends StatelessWidget {
  final List<StepItem> steps;
  final Set<int> completed;
  final int currentStep;
  final bool introWatched;
  final VoidCallback onNeedWatchIntro;
  final VoidCallback onJumpToCurrent;
  final void Function(int stepIndex1) onTapLocked;

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
    final total    = steps.length;
    final finished = completed.length.clamp(0, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Progress summary row ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
          child: Row(
            children: [
              // Completed count pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: finished == total && total > 0
                      ? _kSuccessBg
                      : _kFieldCream,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: finished == total && total > 0
                        ? _kSuccessBorder
                        : _kLightPaw,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      finished == total && total > 0
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_checked_rounded,
                      size: 13,
                      color: finished == total && total > 0
                          ? _kSuccessGreen
                          : _kPrimaryBrown,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$finished / $total ขั้นตอน',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: finished == total && total > 0
                            ? _kSuccessGreen
                            : _kDarkBrown,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Jump to current button (only if intro watched)
              
            ],
          ),
        ),

        // ── Step dots scroll ──────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: List.generate(steps.length, (i) {
              final step   = steps[i];
              final isDone = completed.contains(step.index1Based);
              final isCur  = currentStep == step.index1Based;
              final isLast = i == steps.length - 1;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Dot node ────────────────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      if (!introWatched) {
                        onNeedWatchIntro();
                        return;
                      }
                      if (isCur) {
                        onJumpToCurrent();
                      } else {
                        onTapLocked(step.index1Based);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: isCur ? 38 : 34,
                      height: isCur ? 38 : 34,
                      decoration: BoxDecoration(
                        color: isDone
                            ? _kSuccessGreen
                            : isCur
                                ? _kDarkBrown
                                : _kFieldCream,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone
                              ? _kSuccessBorder
                              : isCur
                                  ? _kDarkBrown
                                  : _kLightPaw,
                          width: isCur ? 2 : 1,
                        ),
                        boxShadow: isCur
                            ? [
                                BoxShadow(
                                  color: _kDarkBrown.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: isDone
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : Text(
                              '${step.index1Based}',
                              style: TextStyle(
                                fontSize: isCur ? 14 : 12,
                                fontWeight: FontWeight.w800,
                                color: isCur
                                    ? Colors.white
                                    : _kPrimaryBrown,
                              ),
                            ),
                    ),
                  ),

                  // ── Connector line (not after last) ──────────────────────
                  if (!isLast)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 20,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isDone ? _kSuccessGreen : _kLightPaw,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}