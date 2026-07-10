import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A glass-morphism container that uses [BackdropFilter] properly.
///
/// Rules:
///  - [blur] must be > 0 to trigger the backdrop pass.
///  - On web, blur is disabled by default (BackdropFilter is not supported on all browsers).
///  - The container paints a semi-transparent background so the blur has something to blur behind it.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color; // tint overlay; if null, uses default
  final BorderRadius borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.opacity = 0.06,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF95D3BA);

    // The container that sits BEHIND the BackdropFilter layer
    final bg = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: opacity),
        borderRadius: borderRadius,
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
      ),
      child: child,
    );

    // Don't waste an offscreen buffer when blur is 0 or on web
    if (blur == 0.0 || kIsWeb) {
      return ClipRRect(borderRadius: borderRadius, child: bg);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: bg,
      ),
    );
  }
}
