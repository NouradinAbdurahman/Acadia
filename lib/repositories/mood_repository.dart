import '../../models/mood.dart';
import '../../services/supabase/mood_service.dart';

class MoodRepository {
  final MoodService _moodService;

  MoodRepository(this._moodService);

  Future<List<MoodModel>> getMoods() async {
    final data = await _moodService.getMoods();
    return data.map((json) => MoodModel.fromJson(json)).toList();
  }

  Future<MoodModel> createMood(MoodModel mood) async {
    final data = mood.toJson();
    data.remove('id');
    // For date, defaults are set in DB but we might have a specific date
    final response = await _moodService.createMood(data);
    return MoodModel.fromJson(response);
  }
}
