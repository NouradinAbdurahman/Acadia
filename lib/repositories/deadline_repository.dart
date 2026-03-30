import '../../models/deadline.dart';
import '../../services/supabase/deadline_service.dart';

class DeadlineRepository {
  final DeadlineService _deadlineService;

  DeadlineRepository(this._deadlineService);

  Future<List<Deadline>> getDeadlines(String userId) async {
    final data = await _deadlineService.getDeadlines(userId);
    return data
        .map((json) => Deadline.fromJson(json))
        .toList();
  }

  Future<Deadline> createDeadline(
    Deadline deadline,
  ) async {
    final data = deadline.toJson()
      ..remove('id')
      ..remove('created_at');
    final response = await _deadlineService.createDeadline(data);
    return Deadline.fromJson(response);
  }

  Future<Deadline> updateDeadline(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final response = await _deadlineService.updateDeadline(id, patch);
    return Deadline.fromJson(response);
  }

  Future<void> deleteDeadline(String id) async {
    await _deadlineService.deleteDeadline(id);
  }
}

