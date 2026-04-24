import '../services/supabase/ai_assistant_service.dart';
import '../models/ai_message.dart';

class AiAssistantRepository {
  AiAssistantRepository(this._service);

  final AiAssistantService _service;

  Future<AiMessage> sendMessage({
    required List<AiMessage> history,
    required String? semesterId,
  }) async {
    final result = await _service.sendMessage(history, semesterId);
    return AiMessage(
      text: result['reply'] as String? ?? '',
      isUser: false,
      type: result['type'] as String? ?? 'text',
      data: result['data'],
      intent: result['intent'] as String?,
      summaryMetadata: result['summaryMetadata'] as Map<String, dynamic>?,
      suggestions: (result['suggestions'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }
}
