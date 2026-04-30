import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  static const double _edgeTriggerWidth = 28;
  static const double _popDistance = 72;

  bool _tracking = false;
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    final canPop = GoRouter.of(context).canPop();

    // Only enable on screens that can navigate back (same semantic as back button).
    if (!canPop) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        final width = MediaQuery.sizeOf(context).width;
        final fromRightEdge = details.globalPosition.dx >=
            (width - _edgeTriggerWidth);
        _tracking = fromRightEdge;
        _dragDistance = 0;
      },
      onHorizontalDragUpdate: (details) {
        if (!_tracking) return;
        // Left swipe from right edge produces negative delta.
        _dragDistance += -details.delta.dx;
      },
      onHorizontalDragEnd: (_) {
        if (_tracking && _dragDistance >= _popDistance && context.mounted) {
          context.pop();
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
