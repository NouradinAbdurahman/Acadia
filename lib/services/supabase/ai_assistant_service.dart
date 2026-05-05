import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/ai_message.dart';

class AiAssistantService {
  final SupabaseClient _client;

  AiAssistantService(this._client);

  Future<Map<String, dynamic>> sendMessage(
    List<AiMessage> history,
    String? semesterId, {
    Map<String, dynamic>? moodContext,
  }) async {
    // Convert message history to the format expected by the Edge Function (OpenAI format)
    // Limit to last 6 messages to keep context window manageable and snappy
    final messages = history.reversed.take(6).toList().reversed.map((m) => {
      'role': m.isUser ? 'user' : 'assistant',
      'content': m.text,
      'intent': m.intent,
      'data': m.data,
    }).toList();

    // Previous assistant turn — used for "send this to email" and structured lastData.
    Map<String, dynamic>? clientContext;
    for (var i = history.length - 2; i >= 0; i--) {
      final m = history[i];
      if (!m.isUser) {
        clientContext = {
          'lastAssistantText': m.text,
          'lastAssistantType': m.type,
          if (m.intent != null) 'lastAssistantIntent': m.intent,
          if (m.data != null) 'lastData': m.data,
        };
        break;
      }
    }

    final response = await _client.functions.invoke(
      'acadia-ai',
      body: {
        'messages': messages,
        'semesterId': semesterId,
        if (moodContext != null) 'moodContext': moodContext,
        if (clientContext != null) 'context': clientContext,
      },
    ).timeout(const Duration(seconds: 12));

    if (response.status != 200) {
      final raw = response.data;
      var message = 'Failed to get response from AI';
      if (raw is Map) {
        message = (raw['error'] as String?) ??
            (raw['reply'] as String?) ??
            message;
      }
      throw Exception(message);
    }

    return response.data as Map<String, dynamic>;
  }
}
