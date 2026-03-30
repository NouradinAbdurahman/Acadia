import '../models/study_session.dart';
import '../services/supabase/study_service.dart';

class StudyRepository {
  final StudyService _studyService;

  StudyRepository(this._studyService);

  Future<List<StudySession>> getSessions(String userId) async {
    final List<dynamic> data = await _studyService.getSessions(userId);
    return data.map((json) => StudySession.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<StudySession> createSession(StudySession session) async {
    final Map<String, dynamic> data = session.toJson()
      ..remove('id');
    
    final response = await _studyService.createSession(data);
    return StudySession.fromJson(response);
  }
}
