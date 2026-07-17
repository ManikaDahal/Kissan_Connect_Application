import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable blur loading overlay widget.
/// Wrap your screen's body with this widget and pass [isLoading] to control
/// when the blur overlay with a spinner is shown.
///
/// Usage:
/// ```dart
/// BlurLoadingOverlay(
///   isLoading: _isLoading,
///   child: YourScaffoldBody(),
/// )
/// ```
class BlurLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const BlurLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
