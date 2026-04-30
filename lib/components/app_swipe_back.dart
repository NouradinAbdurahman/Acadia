import 'package:flutter/material.dart';

/// Shared back-swipe behavior for screens that can pop.
///
/// UX requirement: if a page shows a back button, users can also swipe left
/// (starting near the right edge) to go back.
class AppSwipeBack extends StatefulWidget {
  const AppSwipeBack({super.key, required this.child});

  final Widget child;

  @override
  State<AppSwipeBack> createState() => _AppSwipeBackState();
}

class _AppSwipeBackState extends State<AppSwipeBack> {
  static const double _edgeTriggerWidth = 40;
  static const double _popDistance = 48;

  bool _tracking = false;
  bool _startedFromLeftEdge = false;
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        final width = MediaQuery.sizeOf(context).width;
        final fromLeftEdge = details.globalPosition.dx <= _edgeTriggerWidth;
        final fromRightEdge =
            details.globalPosition.dx >= (width - _edgeTriggerWidth);
        _tracking = fromLeftEdge || fromRightEdge;
        _startedFromLeftEdge = fromLeftEdge;
        _dragDistance = 0;
      },
      onHorizontalDragUpdate: (details) {
        if (!_tracking) return;
        // Support both common back gestures:
        // - iOS-like: right swipe from left edge
        // - requested fallback: left swipe from right edge
        final delta = _startedFromLeftEdge ? details.delta.dx : -details.delta.dx;
        _dragDistance += delta;
      },
      onHorizontalDragEnd: (_) {
        if (_tracking && _dragDistance >= _popDistance && context.mounted) {
          // Try nearest navigator first (works for nested stacks / shell routes).
          final didPopNearest =
              Navigator.maybeOf(context)?.maybePop() ?? Future<bool>.value(false);
          didPopNearest.then((popped) {
            if (popped || !context.mounted) return;
            // Fallback: attempt root navigator pop.
            Navigator.maybeOf(context, rootNavigator: true)?.maybePop();
          });
        }
        _tracking = false;
        _dragDistance = 0;
      },
      onHorizontalDragCancel: () {
        _tracking = false;
        _dragDistance = 0;
      },
      child: widget.child,
    );
  }
}
