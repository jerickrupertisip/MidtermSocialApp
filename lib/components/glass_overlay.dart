import "dart:ui";
import "package:flutter/material.dart";

class GlassOverlay extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const GlassOverlay({
    super.key,
    required this.child,
    this.blurSigma = 10.0,
    this.opacity = 0.2,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        // The sigma values determine how intense the blur is
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            // A slight tint helps the text pop even more
            color: Colors.black.withValues(alpha: opacity),
            borderRadius: borderRadius,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
