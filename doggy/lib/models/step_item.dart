class StepItem {
  final int index1Based;
  final String text;
  final String image;
  final bool needsClicker;
  final bool needsWhistle;

  const StepItem({
    required this.index1Based,
    required this.text,
    required this.image,
    this.needsClicker = false,
    this.needsWhistle = false,
  });
}
