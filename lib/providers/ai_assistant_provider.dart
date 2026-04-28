import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/ai_assistant_repository.dart';
import '../models/ai_message.dart';
import '../models/ai_intent.dart';
import '../services/ai/intent_parser.dart';
import '../services/ai/data_resolver.dart';
import 'app_providers.dart';
import 'analytics_provider.dart';
import 'decision_provider.dart';
import 'risk_provider.dart';
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
  AiAssistantNotifier({
    required Ref ref,
    required AiAssistantRepository repository,
    required AiIntentParser parser,
    required AiDataResolver resolver,
  })  : _ref = ref,
        _repository = repository,
        _parser = parser,
        _resolver = resolver,
        super(const AiAssistantState());

  final Ref _ref;
  final AiAssistantRepository _repository;
  final AiIntentParser _parser;
  final AiDataResolver _resolver;
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
    final semesterId = _ref.read(activeSemesterProvider).value;

    if (user == null) {
      state = state.copyWith(error: AiAssistantError.unauthenticated);
      return;
    }

    if (semesterId == null) {
      state = state.copyWith(error: AiAssistantError.noActiveSemester);
      return;
    }

    final userMessage = AiMessage(text: trimmed, isUser: true, semesterId: semesterId);
    
    // Add user message to state immediately
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
      // 1. Parse Intent
      final intent = _parser.parse(trimmed);
      
      AiMessage aiMessage;

      // 2. Resolve or Fallback
      if (intent.type != AiIntentType.unknown) {
        // REAL DATA RESOLUTION
        aiMessage = await _resolver.resolve(intent, user.id, semesterId);
      } else {
        // FALLBACK TO LLM (Edge Function)
        final analytics = _ref.read(analyticsProvider).valueOrNull;
        final decision = _ref.read(decisionProvider);
        final risk = _ref.read(riskProvider);
        final studyAnalytics = _ref.read(studyAnalyticsProvider);

        final moodContext = {
          if (analytics != null) ...{
            'dailyStress': analytics.avgDailyStress,
            'sessionStress': analytics.avgSessionStress,
            'trend': analytics.stressTrend,
            'consistency': analytics.consistency,
            'studyDeficit': analytics.studyDeficit,
          },
          'risk': risk?.result.totalScore ?? 0.0,
          'burnout': studyAnalytics.burnoutScore,
          'decisionStress': decision.avgStress,
        };

        aiMessage = await _repository.sendMessage(
          history: updatedMessages,
          semesterId: semesterId,
          moodContext: moodContext,
        );
      }
      
      if (_isCancelled) return;
      
      final fullAiMessage = aiMessage.copyWith(semesterId: semesterId);

      // Add AI message to state
      final latestMessages = List<AiMessage>.from(state.messagesFor(semesterId));
      latestMessages.add(fullAiMessage);

      final finalChats = Map<String, List<AiMessage>>.from(state.chatsBySemester);
      finalChats[semesterId] = latestMessages;

      state = state.copyWith(
        chatsBySemester: finalChats,
        isLoading: false,
        clearError: true,
        lastOpenedIntent: fullAiMessage.intent,
      );

      await _animateTyping(fullAiMessage, semesterId);
    } catch (e) {
      final errorMessage = AiMessage(
        text: 'Something went wrong while connecting to your academic data. Please try again.',
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
    for (int i = 0; i <= fullText.length; i++) {
      if (_isCancelled) {
        message.displayedText = fullText;
        _triggerRebuild();
        return;
      }
      message.displayedText = fullText.substring(0, i);
      _triggerRebuild();
      await Future.delayed(const Duration(milliseconds: 15));
    }
  }

  void _triggerRebuild() {
    state = state.copyWith(chatsBySemester: Map.from(state.chatsBySemester));
  }
}

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  final repository = ref.watch(aiAssistantRepositoryProvider);
  final parser = ref.watch(aiIntentParserProvider);
  final resolver = ref.watch(aiDataResolverProvider);
  return AiAssistantNotifier(
    ref: ref, 
    repository: repository,
    parser: parser,
    resolver: resolver,
  );
});
