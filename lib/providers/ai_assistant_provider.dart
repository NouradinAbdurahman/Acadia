import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/ai_assistant_repository.dart';
import '../models/ai_message.dart';
import 'app_providers.dart';
import 'semester_provider.dart';

enum AiAssistantError {
  emptyMessage,
  unauthenticated,
  noActiveSemester,
  requestFailed,
}

class AiAssistantState {
  const AiAssistantState({
    this.chatsBySemester = const {},
    this.isLoading = false,
    this.error,
    this.lastOpenedIntent,
  });

  final Map<String, List<AiMessage>> chatsBySemester;
  final bool isLoading;
  final AiAssistantError? error;
  final String? lastOpenedIntent;

  AiAssistantState copyWith({
    Map<String, List<AiMessage>>? chatsBySemester,
    bool? isLoading,
    AiAssistantError? error,
    String? lastOpenedIntent,
    bool clearError = false,
  }) {
    return AiAssistantState(
      chatsBySemester: chatsBySemester ?? this.chatsBySemester,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastOpenedIntent: lastOpenedIntent ?? this.lastOpenedIntent,
    );
  }

  List<AiMessage> messagesFor(String? semesterId) {
    if (semesterId == null) return [];
    return chatsBySemester[semesterId] ?? [];
  }
}

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  AiAssistantNotifier({required Ref ref, required AiAssistantRepository repository})
      : _ref = ref,
        _repository = repository,
        super(const AiAssistantState());

  final Ref _ref;
  final AiAssistantRepository _repository;
  bool _isCancelled = false;

  void stopResponse() {
    _isCancelled = true;
    state = state.copyWith(isLoading: false);
  }

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(error: AiAssistantError.emptyMessage);
      return;
    }

    final user = _ref.read(currentUserProvider);
    final semesterId = _ref.read(activeSemesterProvider);

    if (user == null) {
      state = state.copyWith(error: AiAssistantError.unauthenticated);
      return;
    }

    if (semesterId == null) {
      state = state.copyWith(error: AiAssistantError.noActiveSemester);
      return;
    }

    final userMessage = AiMessage(text: trimmed, isUser: true, semesterId: semesterId);
    
    // Add user message to the correct semester's list
    final currentMessages = state.messagesFor(semesterId);
    final updatedMessages = [...currentMessages, userMessage];
    
    final updatedChats = Map<String, List<AiMessage>>.from(state.chatsBySemester);
    updatedChats[semesterId] = updatedMessages;

    state = state.copyWith(
      chatsBySemester: updatedChats,
      isLoading: true,
      clearError: true,
    );

    _isCancelled = false;

    try {
      final aiMessage = await _repository.sendMessage(
        history: updatedMessages,
        semesterId: semesterId,
      );
      
      if (_isCancelled) return;
      
      final fullAiMessage = aiMessage.copyWith(semesterId: semesterId);

      // Deduplicate: remove previous messages of same type in this semester
      final latestMessages = List<AiMessage>.from(updatedMessages);
      if (fullAiMessage.type != 'text') {
        latestMessages.removeWhere((m) => m.type == fullAiMessage.type);
      }
      latestMessages.add(fullAiMessage);

      final finalChats = Map<String, List<AiMessage>>.from(state.chatsBySemester);
      finalChats[semesterId] = latestMessages;

      state = state.copyWith(
        chatsBySemester: finalChats,
        isLoading: false,
        clearError: true,
        lastOpenedIntent: fullAiMessage.intent,
      );

      // Animation logic (now per-semester)
      await _animateTyping(fullAiMessage, semesterId);
    } catch (_) {
      final errorMessage = AiMessage(
        text: 'Something went wrong. Please try again.',
        isUser: false,
        semesterId: semesterId,
      );
      
      final currentMessagesAfterError = state.messagesFor(semesterId);
      final finalMessages = [...currentMessagesAfterError, errorMessage];
      
      final finalChats = Map<String, List<AiMessage>>.from(state.chatsBySemester);
      finalChats[semesterId] = finalMessages;

      state = state.copyWith(
        chatsBySemester: finalChats,
        isLoading: false,
      );
      await _animateTyping(errorMessage, semesterId);
    }
  }

  Future<void> _animateTyping(AiMessage message, String semesterId) async {
    String fullText = message.text;
    
    // Always animate for a consistent feel, regardless of length
    for (int i = 0; i <= fullText.length; i++) {
      if (_isCancelled) {
        message.displayedText = fullText;
        _triggerRebuild();
        return;
      }
      
      message.displayedText = fullText.substring(0, i);
      _triggerRebuild();
      
      // 20ms provides a smooth, "streaming" feel that is readable but fast
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  void _triggerRebuild() {
    state = state.copyWith(chatsBySemester: Map.from(state.chatsBySemester));
  }
}

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  final repository = ref.watch(aiAssistantRepositoryProvider);
  return AiAssistantNotifier(ref: ref, repository: repository);
});
