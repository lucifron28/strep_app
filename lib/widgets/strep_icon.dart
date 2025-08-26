import 'package:flutter/material.dart';

class StrepIcon extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  
  const StrepIcon({
    super.key,
    this.size = 24,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Image.asset(
      'assets/icons/icon.png',
      width: size,
      height: size,
      fit: fit,
    );

    if (borderRadius != null) {
      iconWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}
