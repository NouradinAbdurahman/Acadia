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

    final response = await _client.functions.invoke(
      'acadia-ai',
      body: {
        'messages': messages,
        'semesterId': semesterId,
        if (moodContext != null) 'moodContext': moodContext,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.status != 200) {
      throw Exception('Failed to get response from AI');
    }

    return response.data as Map<String, dynamic>;
  }
}
