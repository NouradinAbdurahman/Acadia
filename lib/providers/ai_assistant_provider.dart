import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/ai_assistant_repository.dart';
import '../models/ai_message.dart';
import '../models/ai_intent.dart';
import '../services/ai/intent_parser.dart';
import '../services/ai/data_resolver.dart';
import '../services/ai/ai_consistency_debug.dart';
import 'app_providers.dart';
import 'adaptive_provider.dart';
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

  bool _isEmailDeliveryQuery(String message) {
    final m = message.toLowerCase().trim();
    if (RegExp(r'\bemail\s+me\b').hasMatch(m)) return true;
    final targetsEmail =
        m.contains('email') || m.contains('e-mail') || m.contains('inbox');
    if (targetsEmail &&
        RegExp(r'\b(send|forward|mail|deliver|shoot|push|get)\b').hasMatch(m)) {
      return true;
    }
    if (RegExp(r'\b(send|mail)\s+this\b').hasMatch(m) ||
        RegExp(r'\bmail\s+this\b').hasMatch(m)) {
      return true;
    }
    if (RegExp(r'\bto\s+(my\s+)?(email|e-?mail|inbox)\b').hasMatch(m) &&
        RegExp(r'\b(send|forward|mail|get)\b').hasMatch(m)) {
      return true;
    }
    return false;
  }

  bool _isAcademicScopedQuery(String message) {
    final m = message.toLowerCase().trim();
    if (_isEmailDeliveryQuery(m)) return true;
    const academicPatterns = [
      // High-level assistant intents
      r'\b(summary|recap|progress|stats|performance|dashboard|overview|report)\b',
      r'\b(plan today|plan_today|plan my week|plan_week|focus now|focus_now|review deadlines|email summary)\b',
      r'\b(start focus|start session|study now)\b',
      r'\b(email my tasks|send to email|send this to email|mail this)\b',

      // Task + deadline domain
      r'\b(task|tasks|todo|to-do|assignment|assignments|deadline|deadlines|due|due date)\b',
      r'\b(overdue|due soon|incomplete|uncompleted|completed|pending|open tasks?|unfinished)\b',
      r'\b(priority|urgent|high priority|medium priority|low priority)\b',

      // Study/session domain
      r'\b(study|study session|sessions|pomodoro|deep work|review mode|timer|focus block)\b',
      r'\b(study goal|weekly goal|study deficit|hours logged|weekly average|consistency)\b',

      // Academic performance domain
      r'\b(gpa|grade|grades|course result|results|letter grade|credits|ects|cgpa)\b',
      r'\b(exam|exams|quiz|quizzes|midterm|final|project|coursework)\b',
      r'\b(risk|academic risk|burnout|stress|mood|energy|trend|trends)\b',

      // Course/semester/profile domain
      r'\b(course|courses|class|classes|subject|subjects|semester|term|active semester)\b',
      r'\b(university|major|degree|profile|academic profile|study preference)\b',

      // Notifications/reminders domain
      r'\b(notification|notifications|reminder|reminders|alert|alerts|inbox)\b',
      r'\b(read|unread|mark as read|push notification)\b',

      // Time/date filters used by resolver/parser
      r'\b(today|tomorrow|yesterday|this week|last week|next week|next 7 days|last 2 weeks)\b',
      r'\b(this month|last month|calendar week|semester week)\b',
      r'\b(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\b',
      r'\b\d{4}\b',
    ];
    return academicPatterns.any((p) => RegExp(p).hasMatch(m));
  }

  AiMessage? _localSmallTalkReply(String message, String semesterId) {
    final m = message.trim().toLowerCase();
    if (RegExp(r'^(hi|hello|hey|yo)\b').hasMatch(m)) {
      return AiMessage(
        text:
            "Hi! I can help with your summary, tasks, deadlines, risk, and study progress for this semester.",
        isUser: false,
        semesterId: semesterId,
      );
    }
    if (RegExp(r'^(who are you|what are you|what can you do)\b').hasMatch(m)) {
      return AiMessage(
        text:
            "I'm your Acadia study companion. Ask me things like: summary, incomplete tasks this week, deadlines in April, or your current risk.",
        isUser: false,
        semesterId: semesterId,
      );
    }
    return null;
  }

  AiIntentType _inferLocalAcademicIntent(String message) {
    final m = message.toLowerCase();
    if (RegExp(r'\b(risk|burnout|warning|danger|struggling)\b').hasMatch(m)) {
      return AiIntentType.getRiskStatus;
    }
    if (RegExp(r'\b(deadline|deadlines|due)\b').hasMatch(m)) {
      return AiIntentType.getUpcomingDeadlines;
    }
    if (RegExp(r'\b(gpa|gba|cgpa|grade|grades|result|results|performance|stats|progress)\b')
        .hasMatch(m)) {
      return AiIntentType.getProgress;
    }
    if (RegExp(r'\b(focus now|focus_now|start focus|start session|study now)\b')
        .hasMatch(m)) {
      return AiIntentType.focusNow;
    }
    if (RegExp(r'\b(plan today|plan_today|today plan|what should i study today)\b')
        .hasMatch(m)) {
      return AiIntentType.planToday;
    }
    if (RegExp(r'\b(task|tasks|todo|assignment|summary|plan today|plan_today)\b')
        .hasMatch(m)) {
      return AiIntentType.getStudySummary;
    }
    return AiIntentType.getStudySummary;
  }

  void stopResponse() {
    _isCancelled = true;
    state = state.copyWith(isLoading: false);
  }

  void clearChatForSemester(String? semesterId) {
    if (semesterId == null) return;
    final updatedChats = Map<String, List<AiMessage>>.from(state.chatsBySemester);
    updatedChats.remove(semesterId);
    _isCancelled = true;
    state = state.copyWith(
      chatsBySemester: updatedChats,
      isLoading: false,
      clearError: true,
      lastOpenedIntent: null,
    );
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
      final localSmallTalk = _localSmallTalkReply(trimmed, semesterId);
      if (localSmallTalk != null) {
        final latestMessages = List<AiMessage>.from(state.messagesFor(semesterId));
        latestMessages.add(localSmallTalk);
        final finalChats = Map<String, List<AiMessage>>.from(state.chatsBySemester);
        finalChats[semesterId] = latestMessages;
        state = state.copyWith(
          chatsBySemester: finalChats,
          isLoading: false,
          clearError: true,
        );
        await _animateTyping(localSmallTalk, semesterId);
        return;
      }

      if (!_isAcademicScopedQuery(trimmed)) {
        final strictScope = AiMessage(
          text:
              "I can only answer Acadia academic questions. Ask about your summary, tasks, deadlines, study sessions, risk, GPA, or progress.",
          isUser: false,
          semesterId: semesterId,
        );
        final latestMessages = List<AiMessage>.from(state.messagesFor(semesterId));
        latestMessages.add(strictScope);
        final finalChats = Map<String, List<AiMessage>>.from(state.chatsBySemester);
        finalChats[semesterId] = latestMessages;
        state = state.copyWith(
          chatsBySemester: finalChats,
          isLoading: false,
          clearError: true,
        );
        await _animateTyping(strictScope, semesterId);
        return;
      }

      // 1. Parse Intent
      var intent = _parser.parse(trimmed);
      // Academic unknowns should still resolve locally from DB-backed providers.
      if (intent.type == AiIntentType.unknown &&
          _isAcademicScopedQuery(trimmed) &&
          !_isEmailDeliveryQuery(trimmed)) {
        intent = AiIntent(
          type: _inferLocalAcademicIntent(trimmed),
          filter: intent.filter,
          originalMessage: intent.originalMessage,
        );
      }
      
      AiMessage aiMessage;

      // 2. Resolve or Fallback
      if (intent.type != AiIntentType.unknown) {
        // Use the same pre-computed data the app UI displays
        final analyticsSnapshot = _ref.read(analyticsProvider).valueOrNull;
        final adaptiveProfileSnapshot = _ref.read(adaptiveProfileProvider);
        final riskSnapshot = _ref.read(riskProvider);
        aiMessage = await _resolver.resolve(
          intent,
          user.id,
          semesterId,
          analyticsSnapshot: analyticsSnapshot,
          riskSnapshot: riskSnapshot.hasData ? riskSnapshot : null,
          adaptiveProfileSnapshot: adaptiveProfileSnapshot,
          burnoutRiskSnapshot: analyticsSnapshot?.burnoutScore ?? 0.0,
        );
      } else {
        // FALLBACK TO LLM (Edge Function)
        final analytics = _ref.read(analyticsProvider).valueOrNull;
        final decision = _ref.read(decisionProvider);
        final risk = _ref.read(riskProvider);

        final moodContext = {
          if (analytics != null) ...{
            'dailyStress': analytics.avgDailyStress,
            'sessionStress': analytics.avgSessionStress,
            'trend': analytics.stressTrend,
            'consistency': analytics.consistency,
            'studyDeficit': analytics.studyDeficit,
          },
          'risk': risk.result.totalScore,
          if (risk.hasData)
            'riskDetail': {
              'score': risk.result.totalScore,
              'level': risk.result.riskLevel,
              'overdueTasks': risk.input.overdueTasks,
              'upcomingTasks': risk.input.upcomingTasks,
              'studyDeficit': risk.input.studyDeficit,
              'avgSessionStress': risk.input.avgSessionStress,
              'consistency': risk.input.consistency,
              if (risk.trendDelta != null) 'trendDelta': risk.trendDelta,
            },
          'burnout': analytics?.burnoutScore ?? 0.0,
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

      logAiDeterministicConsistency(
        message: fullAiMessage,
        analytics: _ref.read(analyticsProvider).valueOrNull,
        riskState: _ref.read(riskProvider),
        adaptiveProfile: _ref.read(adaptiveProfileProvider),
        burnoutRisk: _ref.read(analyticsProvider).valueOrNull?.burnoutScore ?? 0.0,
      );

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
      final fallback = _ref.read(analyticsProvider).valueOrNull;
      final fallbackMessage = (fallback != null && fallback.hasData)
          ? "I couldn't reach the cloud AI right now. Try a local query like 'summary', 'tasks this week', or 'deadlines in April'."
          : 'Something went wrong while connecting to your academic data. Please try again.';
      final errorMessage = AiMessage(
        text: fallbackMessage,
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
