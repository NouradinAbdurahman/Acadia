import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/risk_provider.dart';
import '../../components/app_toast.dart';
import 'passive_ai_constants.dart';

/// Invisible widget that subscribes to [riskProvider] and surfaces meaningful
/// score jumps via [SnackBar] (debug-friendly product signal).
class PassiveAiRiskListener extends ConsumerStatefulWidget {
  const PassiveAiRiskListener({super.key});

  @override
  ConsumerState<PassiveAiRiskListener> createState() =>
      _PassiveAiRiskListenerState();
}

class _PassiveAiRiskListenerState extends ConsumerState<PassiveAiRiskListener> {
  double? _lastScore;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(riskProvider, (previous, next) {
      if (!next.hasData) return;

      final score = next.result.totalScore.toDouble();

      if (!_initialized) {
        _initialized = true;
        _lastScore = score;
        return;
      }

      final prev = _lastScore;
      _lastScore = score;
      if (prev == null) return;

      final delta = (score - prev).abs();
      if (delta < kPassiveAiRiskDeltaSnack) return;

      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        AppToast.show(context, l10n.aiPassiveRiskSpike, type: AppToastType.info);
      });
    });

    return const SizedBox.shrink();
  }
}
