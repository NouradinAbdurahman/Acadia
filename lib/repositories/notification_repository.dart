import '../models/notification.dart';
import '../services/supabase/notification_service.dart';

class NotificationRepository {
  final NotificationService _service;

  NotificationRepository(this._service);

  Future<List<NotificationModel>> getNotifications({
    required String userId,
    required String semesterId,
  }) async {
    final data = await _service.getNotifications(
      userId: userId,
      semesterId: semesterId,
    );
    return data.map((json) => NotificationModel.fromJson(json)).toList();
  }

  Future<NotificationModel> markAsRead(String id) async {
    final data = await _service.markAsRead(id);
    return NotificationModel.fromJson(data);
  }

  Future<NotificationModel> createNotification(NotificationModel notification) async {
    final data = await _service.createNotification(notification.toJson());
    return NotificationModel.fromJson(data);
  }

  Future<void> markAllAsRead(List<String> ids) async {
    await _service.markAllAsRead(ids);
  }
}
