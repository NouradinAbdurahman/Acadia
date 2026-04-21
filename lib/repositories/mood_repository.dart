import '../models/mood_log.dart';
import '../models/mood_settings.dart';
import '../../services/supabase/mood_service.dart';

class MoodRepository {
  final MoodService _moodService;

  MoodRepository(this._moodService);

  Future<MoodLog> insertMood(MoodLog mood) async {
    final payload = mood.toJson()..remove('id');
    final response = await _moodService.insertMood(payload);
    return MoodLog.fromJson(response);
  }

  Future<List<MoodLog>> getMoodLogs({
    required String semesterId,
  }) async {
    final data = await _moodService.getMoodLogs(semesterId: semesterId);
    return data.map(MoodLog.fromJson).toList();
  }

  Future<MoodSettings?> getMoodSettings({required String userId}) async {
    final response = await _moodService.getMoodSettings(userId: userId);
    if (response == null) return null;
    return MoodSettings.fromJson(response);
  }

  Future<MoodSettings> upsertMoodSettings(MoodSettings settings) async {
    final response = await _moodService.upsertMoodSettings(settings.toJson());
    return MoodSettings.fromJson(response);
  }
}
