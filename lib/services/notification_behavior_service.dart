import 'package:shared_preferences/shared_preferences.dart';

class NotificationBehaviorStats {
  final int sent;
  final int opened;

  const NotificationBehaviorStats({required this.sent, required this.opened});

  int get ignored => (sent - opened).clamp(0, sent);
}

class NotificationBehaviorService {
  static const String _sentPrefix = 'notif_behavior_sent_';
  static const String _openedPrefix = 'notif_behavior_opened_';
  static const String _dailySentPrefix = 'notif_behavior_daily_sent_';
  static const String _dailyHighPrefix = 'notif_behavior_daily_high_';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static String _dayKey([DateTime? now]) {
    final value = (now ?? DateTime.now()).toUtc();
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  static String _typeKey(String type) => type.trim().toLowerCase();

  static Future<int> _readInt(String key) async {
    final prefs = await _instance();
    return prefs.getInt(key) ?? 0;
  }

  static Future<void> recordSent(
    String type, {
    bool highPriority = false,
  }) async {
    final normalized = _typeKey(type);
    final prefs = await _instance();
    await prefs.setInt(
      '$_sentPrefix$normalized',
      (prefs.getInt('$_sentPrefix$normalized') ?? 0) + 1,
    );

    final day = _dayKey();
    await prefs.setInt(
      '$_dailySentPrefix$day',
      (prefs.getInt('$_dailySentPrefix$day') ?? 0) + 1,
    );

    if (highPriority) {
      await prefs.setInt(
        '$_dailyHighPrefix$day',
        (prefs.getInt('$_dailyHighPrefix$day') ?? 0) + 1,
      );
    }
  }

  static Future<void> recordOpened(String type) async {
    final normalized = _typeKey(type);
    final prefs = await _instance();
    await prefs.setInt(
      '$_openedPrefix$normalized',
      (prefs.getInt('$_openedPrefix$normalized') ?? 0) + 1,
    );
  }

  static Future<NotificationBehaviorStats> statsFor(String type) async {
    final normalized = _typeKey(type);
    final sent = await _readInt('$_sentPrefix$normalized');
    final opened = await _readInt('$_openedPrefix$normalized');
    return NotificationBehaviorStats(sent: sent, opened: opened);
  }

  static Future<bool> ignoredTooMuch(String type) async {
    final stats = await statsFor(type);
    return stats.ignored > 3;
  }

  static Future<bool> userEngages(String type) async {
    final stats = await statsFor(type);
    if (stats.sent == 0) return false;
    return stats.opened > (stats.sent / 2);
  }

  static Future<bool> canSendDaily() async {
    final day = _dayKey();
    return await _readInt('$_dailySentPrefix$day') < 5;
  }

  static Future<bool> canSendHighPriority() async {
    final day = _dayKey();
    return await _readInt('$_dailyHighPrefix$day') < 2;
  }

  static Future<int> sentToday() async {
    return _readInt('$_dailySentPrefix${_dayKey()}');
  }

  static Future<int> highPrioritySentToday() async {
    return _readInt('$_dailyHighPrefix${_dayKey()}');
  }

  static Map<String, int> snapshotKeys() {
    final prefs = _prefs;
    if (prefs == null) {
      return const {};
    }

    final result = <String, int>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_sentPrefix) && !key.startsWith(_openedPrefix)) continue;
      result[key] = prefs.getInt(key) ?? 0;
    }
    return result;
  }
}