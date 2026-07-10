import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // لاستيراد kIsWeb

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final BorderRadius borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.05,
    this.color = const Color(0xFF95D3BA), // Soft Mint overlay default
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color.withOpacity(kIsWeb ? (opacity + 0.03) : opacity),
        borderRadius: borderRadius,
        border: border ?? Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.0,
        ),
      ),
      child: child,
    );

    if (kIsWeb || blur == 0.0) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: container,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: container,
      ),
    );
  }
}
