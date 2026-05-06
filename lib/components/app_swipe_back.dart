import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/navigation/navigation_keys.dart';

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

class _AppSwipeBackState extends State<AppSwipeBack>
    with SingleTickerProviderStateMixin {
  static const double _edgeTriggerWidth = 24;
  static const double _completeThreshold = 0.34;
  static const double _minFlingVelocity = 950;

  late final AnimationController _controller;
  Animation<double>? _settleAnimation;

  bool _tracking = false;
  bool _gestureAccepted = false;
  bool _startedFromLeftEdge = false;
  double _dragDistance = 0;
  double _dxTotal = 0;
  double _dyTotal = 0;
  double _viewportWidth = 1;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isCupertinoPlatform {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  double get _progress => _controller.value.clamp(0.0, 1.0);

  double _resistedProgress(double rawProgress) {
    final clamped = rawProgress.clamp(0.0, 1.0);
    // Smooth resistance curve that feels less abrupt.
    return 1 - (1 / (1 + clamped * 3.4));
  }

  void _resetTracking() {
    _tracking = false;
    _gestureAccepted = false;
    _startedFromLeftEdge = false;
    _dragDistance = 0;
    _dxTotal = 0;
    _dyTotal = 0;
  }

  Future<void> _animateTo(double target) async {
    _settleAnimation = Tween<double>(
      begin: _controller.value,
      end: target,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _isAnimating = true;
    setState(() {});
    await _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    _isAnimating = false;
    _settleAnimation = null;
    if (mounted) setState(() {});
  }

  Future<void> _popWithFallback() async {
    final nearestNavigator = Navigator.maybeOf(context);
    final rootNavigator = Navigator.maybeOf(context, rootNavigator: true);

    final didPopNearest =
        await (nearestNavigator?.maybePop() ?? Future<bool>.value(false));
    if (didPopNearest) return;
    await (rootNavigator?.maybePop() ?? Future<bool>.value(false));
  }

  Future<void> _completePop() async {
    await _animateTo(1);
    if (!mounted) return;
    await _popWithFallback();
    if (!mounted) return;
    _controller.value = 0;
    _resetTracking();
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Haptics may not be available on all targets.
    }
  }

  Future<void> _cancelPop() async {
    await _animateTo(0);
    _resetTracking();
  }

  @override
  Widget build(BuildContext context) {
    // Keep native iOS/macOS interactive pop as source of truth.
    if (_isCupertinoPlatform) return widget.child;

    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        if (_isAnimating) return;
        _viewportWidth = MediaQuery.sizeOf(context).width;
        final canPop =
            rootNavigatorKey.currentState?.canPop() ??
            (Navigator.maybeOf(context)?.canPop() ?? false);
        if (!canPop) {
          _resetTracking();
          return;
        }

        final width = MediaQuery.sizeOf(context).width;
        final fromLeftEdge = details.globalPosition.dx <= _edgeTriggerWidth;
        final fromRightEdge =
            details.globalPosition.dx >= (width - _edgeTriggerWidth);
        _tracking = fromLeftEdge || fromRightEdge;
        _startedFromLeftEdge = fromLeftEdge;
        _gestureAccepted = false;
        _dragDistance = 0;
        _dxTotal = 0;
        _dyTotal = 0;
        _controller.stop();
        _controller.value = 0;
      },
      onHorizontalDragUpdate: (details) {
        if (!_tracking) return;
        _dxTotal += details.delta.dx.abs();
        _dyTotal += details.delta.dy.abs();

        if (!_gestureAccepted) {
          // Reject if user is mostly scrolling vertically.
          if (_dyTotal > _dxTotal && _dyTotal > 6) {
            _resetTracking();
            _controller.value = 0;
            return;
          }
          // Wait for intent before taking over.
          if (_dxTotal < 7) return;
          _gestureAccepted = true;
        }

        final signedDelta = _startedFromLeftEdge ? details.delta.dx : -details.delta.dx;
        _dragDistance = (_dragDistance + signedDelta).clamp(0.0, double.infinity);
        final raw = (_dragDistance / (_viewportWidth * 0.82)).clamp(0.0, 1.0);
        _controller.value = _resistedProgress(raw);
      },
      onHorizontalDragEnd: (details) {
        if (!_tracking) return;
        final velocity = _startedFromLeftEdge
            ? (details.primaryVelocity ?? 0)
            : -(details.primaryVelocity ?? 0);
        final shouldPop =
            _gestureAccepted &&
            (_progress >= _completeThreshold || velocity >= _minFlingVelocity);
        if (shouldPop) {
          _completePop();
        } else {
          _cancelPop();
        }
      },
      onHorizontalDragCancel: () {
        if (!_tracking) return;
        _cancelPop();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _settleAnimation?.value ?? _progress;
          final direction = _startedFromLeftEdge ? 1.0 : -1.0;
          final translateX = direction * progress * _viewportWidth * 0.98;
          final underlayOpacity = (0.04 + (progress * 0.07)).clamp(0.0, 0.12);
          final shadowOpacity = (progress * 0.22).clamp(0.0, 0.22);

          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: theme.scaffoldBackgroundColor),
              IgnorePointer(
                ignoring: true,
                child: Container(
                  color: Colors.black.withValues(alpha: underlayOpacity),
                ),
              ),
              Transform.translate(
                offset: Offset(translateX, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: shadowOpacity),
                        blurRadius: 18,
                        offset: const Offset(-3, 0),
                      ),
                    ],
                  ),
                  child: child!,
                ),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}
