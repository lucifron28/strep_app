import 'package:flutter/material.dart';
import '../theme/dracula_theme.dart';

class VinylDisk extends StatefulWidget {
  final double size;
  final bool isSpinning;
  final Color? primaryColor;
  final Color? accentColor;
  
  const VinylDisk({
    super.key,
    this.size = 56,
    this.isSpinning = false,
    this.primaryColor,
    this.accentColor,
  });

  @override
  State<VinylDisk> createState() => _VinylDiskState();
}

class _VinylDiskState extends State<VinylDisk>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    if (widget.isSpinning) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(VinylDisk oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? DraculaTheme.currentLine;
    final accentColor = widget.accentColor ?? DraculaTheme.purple;
    
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2.0 * 3.141592653589793,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: VinylDiskPainter(
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
          ),
        );
      },
    );
  }
}

class VinylDiskPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  
  VinylDiskPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer vinyl disk with gradient
    final outerGradient = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.9),
        primaryColor,
        DraculaTheme.background.withValues(alpha: 0.8),
      ],
      stops: const [0.0, 0.7, 1.0],
    );
    
    final outerPaint = Paint()
      ..shader = outerGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    
    canvas.drawCircle(center, radius, outerPaint);

    // Vinyl grooves (concentric circles)
    final groovePaint = Paint()
      ..color = DraculaTheme.background.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    for (int i = 1; i <= 8; i++) {
      final grooveRadius = radius * (0.3 + (i * 0.08));
      canvas.drawCircle(center, grooveRadius, groovePaint);
    }

    // Inner label area with accent gradient
    final labelRadius = radius * 0.35;
    final labelGradient = RadialGradient(
      colors: [
        accentColor.withValues(alpha: 0.8),
        accentColor.withValues(alpha: 0.6),
        accentColor.withValues(alpha: 0.3),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    
    final labelPaint = Paint()
      ..shader = labelGradient.createShader(
        Rect.fromCircle(center: center, radius: labelRadius),
      );
    
    canvas.drawCircle(center, labelRadius, labelPaint);

    // Center hole with dark shadow
    final centerHoleRadius = radius * 0.08;
    final shadowPaint = Paint()
      ..color = DraculaTheme.background.withValues(alpha: 0.9);
    
    canvas.drawCircle(center, centerHoleRadius + 2, shadowPaint);
    
    final holePaint = Paint()
      ..color = DraculaTheme.background;
    
    canvas.drawCircle(center, centerHoleRadius, holePaint);

    // Highlight reflection
    final highlightPaint = Paint()
      ..color = DraculaTheme.foreground.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.8),
      -0.5, // Start angle
      1.0,  // Sweep angle
      false,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
