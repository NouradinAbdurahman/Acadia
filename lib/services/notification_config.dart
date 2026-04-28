class NotificationConfig {
  final bool isCritical;
  final bool isSilent;
  final Duration cooldown;
  final bool allowNightDelivery;

  const NotificationConfig({
    required this.isCritical,
    required this.isSilent,
    required this.cooldown,
    this.allowNightDelivery = false,
  });
}

class NotificationTypeConfig {
  static const Map<String, NotificationConfig> values = {
    'risk': NotificationConfig(
      isCritical: true,
      isSilent: false,
      cooldown: Duration(hours: 6),
      allowNightDelivery: true,
    ),
    'overdue': NotificationConfig(
      isCritical: true,
      isSilent: false,
      cooldown: Duration(hours: 4),
      allowNightDelivery: true,
    ),
    'overdue_batch': NotificationConfig(
      isCritical: true,
      isSilent: false,
      cooldown: Duration(hours: 4),
      allowNightDelivery: true,
    ),
    'deadline': NotificationConfig(
      isCritical: false,
      isSilent: false,
      cooldown: Duration(hours: 12),
    ),
    'deadline_batch': NotificationConfig(
      isCritical: false,
      isSilent: false,
      cooldown: Duration(hours: 12),
    ),
    'academic_summary': NotificationConfig(
      isCritical: false,
      isSilent: true,
      cooldown: Duration(hours: 24),
    ),
    'stress': NotificationConfig(
      isCritical: false,
      isSilent: false,
      cooldown: Duration(hours: 12),
    ),
  };

  static NotificationConfig resolve(String type) {
    return values[type] ?? const NotificationConfig(
      isCritical: false,
      isSilent: false,
      cooldown: Duration(hours: 12),
    );
  }
}