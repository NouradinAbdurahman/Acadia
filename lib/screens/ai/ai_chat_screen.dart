import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/ai_assistant_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/risk_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/semester_provider.dart';
import '../../providers/study_sessions_provider.dart';
import '../../models/ai_message.dart';
import '../../theme/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../widgets/ai/ai_insight_text_utils.dart';
import '../../widgets/ai/insight_card.dart';
import '../../widgets/ai/recommendation_card.dart';
import '../../widgets/ai/recommendation_action_utils.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  String? _errorMessage(AiAssistantError? error) {
    switch (error) {
      case AiAssistantError.emptyMessage:
        return 'Please type a message.';
      case AiAssistantError.unauthenticated:
        return 'Please sign in to use the assistant.';
      case AiAssistantError.noActiveSemester:
        return 'No active semester found.';
      case AiAssistantError.requestFailed:
        return 'AI request failed. Please try again.';
      case null:
        return null;
    }
  }

  void _handleAction(String action) {
    _submitPrompt(action);
  }

  void _submitPrompt(String text) {
    if (ref.read(aiAssistantProvider).isLoading) return;
    final prompt = text.trim();
    if (prompt.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(aiAssistantProvider.notifier).sendMessage(prompt);
  }

  void _minimizeChat() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context);
  }

  void _closeAndClearCurrentChat() {
    final semesterId = ref.read(activeSemesterProvider).value;
    ref.read(aiAssistantProvider.notifier).clearChatForSemester(semesterId);
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context);
  }

  List<_ActionItem> _getSmartActions(AiMessage? last) {
    if (last == null || last.isUser) {
      return [
        _ActionItem("Focus now", "focus_now", Icons.bolt),
        _ActionItem("Plan today", "plan_today", Icons.today),
        _ActionItem("Summary", "summary", Icons.summarize_outlined),
      ];
    }

    // Use Dynamic Suggestions from Backend if available
    if (last.suggestions != null && last.suggestions!.isNotEmpty) {
      return last.suggestions!.map((s) {
        return _ActionItem(s, s, Icons.arrow_forward);
      }).toList();
    }

    // 2. Fallback Heuristics
    if (last.type == "summary") {
      return [
        _ActionItem("Review deadlines", "deadlines", Icons.event),
        _ActionItem("Plan today", "plan_today", Icons.today),
        _ActionItem(
          "Email summary",
          "Please send my study summary to my email",
          Icons.mail_outline,
        ),
      ];
    }

    if (last.type == "tasks") {
      return [
        _ActionItem("Plan my week", "plan_week", Icons.calendar_view_week),
        _ActionItem("Focus now", "focus_now", Icons.bolt),
        _ActionItem("Show deadlines", "deadlines", Icons.timer_outlined),
      ];
    }

    return [
      _ActionItem("Focus now", "focus_now", Icons.bolt),
      _ActionItem("Plan today", "plan_today", Icons.today),
      _ActionItem("Summary", "summary", Icons.summarize_outlined),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final semesterId = ref.watch(activeSemesterProvider).value;
    final state = ref.watch(aiAssistantProvider);
    final messages = state.messagesFor(semesterId);
    final isEmpty = messages.isEmpty;
    
    ref.listen<AiAssistantState>(aiAssistantProvider, (previous, next) {
      final prevMessages = previous?.messagesFor(semesterId) ?? [];
      final nextMessages = next.messagesFor(semesterId);
      
      // Always follow the latest content at the bottom.
      if (nextMessages.length > prevMessages.length) {
        _scrollToBottom();
      } else if (next.isLoading) {
        // During typing animation/streaming, keep scrolling to end.
        _scrollToBottom();
      }

      if (previous?.error == next.error || next.error == null) return;
      final message = _errorMessage(next.error);
      if (message == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Acadia Assistant", 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: AppColors.textPrimary(context),
                letterSpacing: -0.5,
              )
            ),
            Builder(builder: (context) {
              final semesterId = ref.watch(activeSemesterProvider).value;
              final state = ref.watch(aiAssistantProvider);
              final messages = state.messagesFor(semesterId);
              final lastMsg = messages.isEmpty ? null : messages.lastWhere((m) => !m.isUser, orElse: () => messages.last);
              
              String insight = "AI Study Companion";
              if (lastMsg != null && lastMsg.summaryMetadata != null) {
                final urgent = lastMsg.summaryMetadata!['urgentCount'] ?? 0;
                if (urgent > 0) {
                  insight = "You have $urgent urgent task${urgent > 1 ? 's' : ''} today.";
                } else {
                  insight = "You're all caught up for now!";
                }
              }

              return Text(
                insight,
                style: TextStyle(
                  fontSize: 12, 
                  color: insight.contains("urgent") ? AppColors.urgent : AppColors.textSecondary(context),
                  fontWeight: FontWeight.w500,
                )
              );
            }),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary(context), size: 26),
          onPressed: _minimizeChat,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: AppColors.textSecondary(context)),
            color: AppColors.aiCard(context),
            onSelected: (value) {
              if (value == 'close_clear') _closeAndClearCurrentChat();
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'close_clear',
                child: Row(
                  children: const [
                    Icon(Icons.delete_forever_outlined, color: Colors.red, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Close & Clear Chat',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        10,
                        AppSpacing.md,
                        24,
                      ),
                      itemCount: messages.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return Container(
                          key: message.key,
                          child: _MessageBubble(message: message),
                        );
                      },
                    ),
            ),
            if (state.isLoading)
              const _ThinkingIndicator(),
            if (!isEmpty) _buildProactiveHints(context),
            _InputArea(
              controller: _controller,
              isLoading: state.isLoading,
              onSend: _submitPrompt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 620;
        final maxContentWidth = constraints.maxWidth < 420 ? constraints.maxWidth : 420.0;
        return Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: isCompact ? 12 : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 20 : 24),
                    decoration: BoxDecoration(
                      color: AppColors.aiCard(context),
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        radius: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      width: isCompact ? 56 : 64,
                      height: isCompact ? 56 : 64,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: isCompact ? 18 : 24),
                  Text(
                    'How can I help with your studies today?',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: isCompact ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'I can help you plan your day, organize your week,\nor focus on what matters most.',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: isCompact ? 13 : 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isCompact ? 22 : 32),
                  _buildSuggestionGrid(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionGrid(BuildContext context) {
    final suggestions = [
      {
        'label': 'Summary',
        'icon': Icons.summarize_outlined,
        'prompt': 'Can you show me my summary?',
      },
      {
        'label': 'Plan Today',
        'icon': Icons.today_outlined,
        'prompt': 'Plan today for me',
      },
      {
        'label': 'Focus Now',
        'icon': Icons.bolt,
        'prompt': 'Focus now',
      },
      {
        'label': 'Plan My Week',
        'icon': Icons.calendar_view_week_outlined,
        'prompt': 'Plan my week',
      },
      {
        'label': 'My Tasks',
        'icon': Icons.task_alt,
        'prompt': 'Show me my uncompleted tasks',
      },
      {
        'label': 'Deadlines',
        'icon': Icons.timer_outlined,
        'prompt': 'What are my upcoming deadlines?',
      },
      {
        'label': 'Rank Tasks',
        'icon': Icons.format_list_numbered_rounded,
        'prompt': 'Rank my tasks',
      },
      {
        'label': 'Academic Risk',
        'icon': Icons.warning_amber_rounded,
        'prompt': 'What is my academic risk?',
      },
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: suggestions.map((s) => InkWell(
        onTap: () => _submitPrompt(s['prompt'] as String),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.aiCard(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(s['icon'] as IconData, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                s['label'] as String,
                style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildProactiveHints(BuildContext context) {
    final semesterId = ref.watch(activeSemesterProvider).value;
    final state = ref.watch(aiAssistantProvider);
    final messages = state.messagesFor(semesterId);
    final lastAiMessage = messages.isEmpty ? null : messages.lastWhere((m) => !m.isUser, orElse: () => messages.last);
    final actions = _getSmartActions(lastAiMessage);

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              avatar: Icon(action.icon, size: 14, color: AppColors.textSecondary(context)),
              label: Text(action.label, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
              onPressed: () => _handleAction(action.intent),
              backgroundColor: AppColors.aiCard(context),
              side: BorderSide(color: AppColors.border(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHintChip(BuildContext context, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: AppColors.textSecondary(context)),
        label: Text(label, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
        onPressed: () => _submitPrompt(label),
        backgroundColor: AppColors.aiCard(context),
        side: BorderSide(color: AppColors.border(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final AiMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isUser 
          ? _buildUserMessage(context) 
          : _buildAiResponseBlock(context, ref),
    );
  }

  Widget _buildUserMessage(BuildContext context) {
    final timeLabel =
        DateFormat.jm().format(message.timestamp.toLocal());
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Text(
                timeLabel,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiResponseBlock(BuildContext context, WidgetRef ref) {
    final isFinished = message.displayedText.length == message.text.length;
    final timeLabel =
        DateFormat.jm().format(message.timestamp.toLocal());

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.aiCard(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 15,
                            height: 1.6,
                          ),
                          children: [
                            TextSpan(text: aiAssistantMainBubbleText(message)),
                            if (!isFinished)
                              TextSpan(
                                text: ' █',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (message.type != 'text' && isFinished)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: _StructuredDataWidget(type: message.type, data: message.data),
                        ),
                      if (isFinished)
                        _InsightRecommendationStrip(message: message),
                      if (isFinished)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: _buildActionChips(context, ref),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isFinished)
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 6),
              child: Text(
                timeLabel,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionChips(BuildContext context, WidgetRef ref) {
    final chips = <Widget>[];

    if (message.type == 'tasks') {
      chips.add(_ActionChip(
        label: 'Send to email',
        icon: Icons.mail_outline,
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          ref.read(aiAssistantProvider.notifier).sendMessage("Could you send this to my email?");
        },
      ));
    }

    if (message.type == 'tasks') {
      chips.add(_ActionChip(
        label: 'What are my deadlines?',
        icon: Icons.timer_outlined,
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          ref.read(aiAssistantProvider.notifier).sendMessage("What are my upcoming deadlines?");
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: chips,
      ),
    );
  }
}

class _ActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _isLoading = false;
  bool _isSuccess = false;

  void _handlePress() async {
    if (_isLoading || _isSuccess) return;
    
    setState(() => _isLoading = true);
    
    // Call the original onPressed
    widget.onPressed();
    
    // Simulate/Wait for action
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      
      // Reset after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _isSuccess = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handlePress,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _isSuccess 
              ? AppColors.completed.withValues(alpha: 0.1) 
              : AppColors.aiCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isSuccess 
                ? AppColors.completed.withValues(alpha: 0.5) 
                : AppColors.border(context)
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            else
              Icon(
                _isSuccess ? Icons.check_rounded : widget.icon, 
                size: 16, 
                color: _isSuccess ? AppColors.completed : AppColors.primary
              ),
            const SizedBox(width: 8),
            Text(
              _isSuccess ? "Sent Successfully" : widget.label,
              style: TextStyle(
                color: _isSuccess ? AppColors.completed : AppColors.textPrimary(context), 
                fontSize: 13, 
                fontWeight: FontWeight.w600
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightRecommendationStrip extends ConsumerWidget {
  final AiMessage message;

  const _InsightRecommendationStrip({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = message.data;
    if (data is! Map) return const SizedBox.shrink();
    final insight = data['insight'];
    final rec = data['recommendation'];
    if (insight is! String || rec is! String) return const SizedBox.shrink();
    if (insight.trim().isEmpty || rec.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final analytics = ref.watch(analyticsProvider).valueOrNull;
    final risk = ref.watch(riskProvider);
    final overdue = analytics?.overdueTasks ??
        (risk.hasData ? risk.input.overdueTasks : 0);
    final deficit = analytics?.studyDeficit ?? 0.0;
    final consistency = analytics?.consistency ?? 1.0;

    final kind = inferRecommendationActionKind(
      recommendation: rec,
      insight: insight,
      overdueTasks: overdue,
      studyDeficitHours: deficit,
      consistency01: consistency,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InsightCard(text: insight),
          const SizedBox(height: 12),
          RecommendationCard(
            text: rec,
            actionKind: kind,
            onAction: kind == null
                ? null
                : () => invokeRecommendationAction(
                      kind: kind,
                      context: context,
                      ref: ref,
                    ),
          ),
        ],
      ),
    );
  }
}

class _StructuredDataWidget extends StatelessWidget {
  final String type;
  final dynamic data;

  const _StructuredDataWidget({required this.type, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox.shrink();

    switch (type) {
      case 'tasks':
        return _TaskDashboard(data: data);
      case 'summary':
        return _SummaryDashboard(data: data);
      case 'profile':
        return _ProfileCard(data: data);
      case 'courses':
        return _GenericListCard(data: data, icon: Icons.book, title: "Courses");
      case 'deadlines':
        return _GenericListCard(data: data, icon: Icons.event_note, title: "Deadlines");
      case 'recommendation':
        return _RecommendationCard(data: data);
      case 'plan':
        return _PlanDashboard(data: data);
      case 'focus':
        return _FocusCard(task: data);
      case 'focus_session':
        return _FocusCard(task: data);
      case 'daily_plan':
        return _DailyPlanCard(data: data);
      case 'daily_plan_empty':
        return _DailyPlanCard(data: data);
      case 'details':
        return _DetailsViewer(data: data);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _PlanDashboard extends StatelessWidget {
  final dynamic data;
  const _PlanDashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> plan = Map<String, dynamic>.from(data ?? {});
    if (plan.isEmpty) return const SizedBox.shrink();

    return Column(
      children: plan.entries.map((day) {
        final tasks = List<String>.from(day.value);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.aiCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day.key.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              ...tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  final dynamic data;
  const _TodayPlanCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final List tasks = data is List ? data : [];
    if (tasks.isEmpty) return const SizedBox.shrink();

    // Top Focus (Big Card)
    final mainTask = tasks[0];
    final subTasks = tasks.length > 1 ? tasks.sublist(1) : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BIG CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "PRIMARY FOCUS",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mainTask['title'] ?? 'Untitled Task',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Deadline: ${mainTask['deadline'] != null ? DateFormat('MMM d, h:mm a').format(DateTime.parse(mainTask['deadline'])) : 'Today'}",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        if (subTasks.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: subTasks.map((task) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: task == subTasks.last ? 0 : 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.nestedCard(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "NEXT",
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task['title'] ?? 'Task',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _DailyPlanCard extends ConsumerWidget {
  final dynamic data;
  const _DailyPlanCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = (data is Map<String, dynamic>)
        ? data as Map<String, dynamic>
        : <String, dynamic>{};
    final sessions = (map['sessions'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
    if (sessions.isEmpty) {
      final duration = (map['duration'] as num?)?.toInt() ?? 30;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.nestedCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Text(
          "You have no tasks for today.\nStart a $duration-minute general study session.",
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY PLAN",
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        ...sessions.map((session) {
          final taskId = session['taskId']?.toString();
          final courseId = session['courseId']?.toString();
          final title = (session['title'] ?? 'Study session').toString();
          final duration = (session['duration'] as num?)?.toInt() ?? 30;
          final slot = (session['slot'] ?? 'Today').toString();
          final reasons = (session['reasons'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.nestedCard(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$duration min • $slot",
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final timer = ref.read(studyTimerProvider.notifier);
                      timer.setDuration(Duration(minutes: duration));
                      timer.setIntent(
                        taskId != null
                            ? "focus_now:$taskId|source:plan_today"
                            : "focus_now|source:plan_today",
                      );
                      if (courseId != null && courseId.isNotEmpty) {
                        timer.setCourseId(courseId);
                      }
                      timer.start();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Started $duration min planned session")),
                      );
                    },
                    child: const Text("Start"),
                  ),
                ),
                if (reasons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Why:",
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...reasons.map(
                    (r) => Text(
                      "• $r",
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _FocusCard extends ConsumerWidget {
  final dynamic task;
  const _FocusCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (task == null) return const SizedBox.shrink();

    final map = (task is Map<String, dynamic>)
        ? task as Map<String, dynamic>
        : <String, dynamic>{};
    final taskId = map['taskId'] ?? map['id'];
    final source = map['source']?.toString();
    final taskTitle = (map['taskTitle'] ?? map['title'] ?? 'Focus session').toString();
    final duration = (map['duration'] as num?)?.toInt() ?? 45;
    final courseId = map['courseId']?.toString();
    final reasons = (map['reasons'] is Map<String, dynamic>)
        ? (map['reasons'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final taskReasons = (reasons['task'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final durationReasons = (reasons['duration'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final deadlineRaw = map['deadline'];
    final deadline = deadlineRaw is String
        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(deadlineRaw))
        : deadlineRaw is DateTime
            ? DateFormat('MMM d, h:mm a').format(deadlineRaw)
            : 'No deadline';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.nestedCard(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "NEXT ACTION",
              style: TextStyle(
                color: AppColors.primary, 
                fontSize: 10, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 1.2,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            taskTitle,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Duration: $duration min${deadline != 'No deadline' ? ' • Due $deadline' : ''}",
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
          if (taskReasons.isNotEmpty || durationReasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            if (taskReasons.isNotEmpty) ...[
              Text(
                "Why this task:",
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              ...taskReasons.map(
                (reason) => Text(
                  "• $reason",
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
            if (durationReasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Why $duration min:",
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              ...durationReasons.map(
                (reason) => Text(
                  "• $reason",
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final timer = ref.read(studyTimerProvider.notifier);
                    timer.setDuration(Duration(minutes: duration));
                    timer.setIntent(taskId != null ? "focus_now:$taskId" : "focus_now");
                    if (courseId != null && courseId.isNotEmpty) {
                      timer.setCourseId(courseId);
                    }
                    timer.start();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Started $duration min focus session")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Start Session", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              if (taskId != null && source == 'task') ...[
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () {
                    ref.read(tasksProvider.notifier).updateTaskStatus(taskId, 'completed');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Task marked as completed!")),
                    );
                  },
                  icon: const Icon(Icons.check),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.completed.withValues(alpha: 0.1),
                    foregroundColor: AppColors.completed,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskDashboard extends StatelessWidget {
  final dynamic data;
  const _TaskDashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data is! Map) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(context, "High Urgency", data['urgent'] ?? [], AppColors.urgent, Icons.warning_amber_rounded),
        _buildSection(context, "Upcoming", data['pending'] ?? [], AppColors.primary, Icons.calendar_today_outlined),
        _buildSection(context, "Completed", data['completed'] ?? [], AppColors.completed, Icons.check_circle_outline, isCompleted: true),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<dynamic> tasks, Color color, IconData icon, {bool isCompleted = false}) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        ...tasks.map((task) => _TaskItem(task: task, isCompleted: isCompleted)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TaskItem extends ConsumerWidget {
  final dynamic task;
  final bool isCompleted;
  const _TaskItem({required this.task, this.isCompleted = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Handle both 'priority' from DB and legacy 'urgency'
    final rawPriority = task['priority']?.toString().toLowerCase() ?? '';
    final urgency = rawPriority.contains('high') ? 'high' : (task['urgency'] ?? 'medium');
    final isUrgent = urgency == 'high' && !isCompleted;
    final deadline = task['deadline'] != null 
        ? DateFormat('MMM d').format(DateTime.parse(task['deadline']))
        : 'No date';
    final taskId = task['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          // Future: Open task details
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.nestedCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUrgent 
                  ? AppColors.urgent.withValues(alpha: 0.5)
                  : AppColors.border(context),
              width: isUrgent ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: isCompleted || taskId == null ? null : () {
                  ref.read(tasksProvider.notifier).updateTaskStatus(taskId, 'completed');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Task marked as completed!")),
                  );
                },
                child: Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  color: isCompleted 
                      ? AppColors.completed 
                      : (isUrgent ? AppColors.urgent : AppColors.textSecondary(context).withValues(alpha: 0.3)),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'] ?? 'Untitled Task',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 10, color: AppColors.textSecondary(context).withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          deadline,
                          style: TextStyle(
                            color: AppColors.textSecondary(context).withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isCompleted && taskId != null)
                IconButton(
                  icon: const Icon(Icons.done_all, size: 18),
                  onPressed: () {
                    ref.read(tasksProvider.notifier).updateTaskStatus(taskId, 'completed');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Task marked as completed!")),
                    );
                  },
                  color: AppColors.primary.withValues(alpha: 0.6),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.urgent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "URGENT",
                    style: TextStyle(
                      color: AppColors.urgent, 
                      fontSize: 8, 
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryDashboard extends StatelessWidget {
  final dynamic data;
  const _SummaryDashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data is! Map) return const SizedBox.shrink();
    
    final total = data['total'] ?? 0;
    final completed = data['completed'] ?? 0;
    final hours = data['hours'] ?? 0;
    final riskScore = data['riskScore'];
    final overdue = data['overdue'] ?? 0;
    final dueSoon = data['dueSoon'] ?? 0;
    final deficit = data['studyDeficit'] ?? 0;
    final consistency = data['consistencyPct'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.nestedCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 84,
            child: _StatItem(
              label: "Tasks",
              value: "$total",
              icon: Icons.assignment_outlined,
              color: AppColors.primary,
            ),
          ),
          SizedBox(
            width: 84,
            child: _StatItem(
              label: "Done",
              value: "$completed",
              icon: Icons.check_circle_outline,
              color: AppColors.completed,
            ),
          ),
          SizedBox(
            width: 84,
            child: _StatItem(
              label: "Hours",
              value: "${hours}h",
              icon: Icons.timer_outlined,
              color: AppColors.statHours,
            ),
          ),
          SizedBox(
            width: 84,
            child: _StatItem(
              label: "Risk",
              value: riskScore == null ? "-" : (riskScore as num).round().toString(),
              icon: Icons.warning_amber_rounded,
              color: AppColors.urgent,
            ),
          ),
          SizedBox(
            width: 84,
            child: _StatItem(
              label: "Overdue",
              value: "$overdue",
              icon: Icons.error_outline,
              color: AppColors.urgent,
            ),
          ),
          SizedBox(
            width: 84,
            child: _StatItem(
              label: "Due Soon",
              value: "$dueSoon",
              icon: Icons.schedule,
              color: AppColors.primary,
            ),
          ),
          SizedBox(
            width: 84,
            child: _StatItem(
              label: "Deficit",
              value: "${(deficit is num ? deficit.toStringAsFixed(1) : deficit)}h",
              icon: Icons.trending_down,
              color: AppColors.statHours,
            ),
          ),
          SizedBox(
            width: 84,
            child: _StatItem(
              label: "Consistency",
              value: consistency == null ? "-" : "$consistency%",
              icon: Icons.track_changes,
              color: AppColors.completed,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color.withValues(alpha: 0.8)),
        const SizedBox(height: 8),
        Text(
          value, 
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 18, fontWeight: FontWeight.bold)
        ),
        Text(
          label, 
          style: TextStyle(color: AppColors.textSecondary(context), fontSize: 11, fontWeight: FontWeight.w500)
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic data;
  const _ProfileCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.nestedCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.aiCard(context),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              (data['full_name'] ?? '?')[0].toUpperCase(), 
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['full_name'] ?? 'Student', 
                  style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 15)
                ),
                const SizedBox(height: 2),
                Text(
                  "${data['major'] ?? 'Academic'} • ${data['university'] ?? 'Institution'}", 
                  style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenericListCard extends StatelessWidget {
  final dynamic data;
  final IconData icon;
  final String title;
  const _GenericListCard({required this.data, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final List items = data is List ? data : [];
    if (items.isEmpty) {
      return Text(
        "No items found.", 
        style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 14),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.nestedCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.circle, size: 6, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['name'] ?? item['title'] ?? 'Unnamed',
                  style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final dynamic data;
  const _RecommendationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.aiCard(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data['message'] ?? 'Summary not available.',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 10,
            width: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Acadia is thinking...',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Function(String) onSend;

  const _InputArea({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        12,
        AppSpacing.md,
        32,
      ),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        border: Border(top: BorderSide(color: AppColors.border(context).withValues(alpha: 0.2), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.aiCard(context),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border(context)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14),
                textInputAction: TextInputAction.send,
                onSubmitted: isLoading ? null : (text) {
                  if (text.trim().isNotEmpty) onSend(text.trim());
                  controller.clear();
                },
                decoration: InputDecoration(
                  hintText: 'Ask your assistant...',
                  hintStyle: TextStyle(color: AppColors.textSecondary(context).withValues(alpha: 0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final hasText = value.text.trim().isNotEmpty;
              final canSend = hasText && !isLoading;
              final isActive = canSend;
              
              return GestureDetector(
                onTap: () {
                  if (canSend) {
                    onSend(value.text.trim());
                    controller.clear();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: canSend
                        ? AppColors.primary
                        : AppColors.textSecondary(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: canSend ? Colors.transparent : AppColors.border(context),
                    ),
                    boxShadow: [
                      if (canSend)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: isActive ? Colors.white : AppColors.textSecondary(context).withValues(alpha: 0.5), 
                    size: 22
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
class _ActionItem {
  final String label;
  final String intent;
  final IconData icon;

  _ActionItem(this.label, this.intent, this.icon);
}
class _DetailsViewer extends StatelessWidget {
  final dynamic data;
  const _DetailsViewer({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox.shrink();
    
    if (data is List) {
      return Column(
        children: data.map((item) => _DetailCard(item: item)).toList(),
      );
    }
    
    return _DetailCard(item: data);
  }
}

class _DetailCard extends StatelessWidget {
  final dynamic item;
  const _DetailCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(item is Map ? item : {});
    if (map.isEmpty) return const SizedBox.shrink();

    // Filter out common metadata and internal IDs for a cleaner view
    final displayEntries = map.entries.where((e) {
      final key = e.key.toLowerCase();
      return e.value != null && 
             !key.contains('id') && 
             !key.contains('_at') && 
             !key.contains('user');
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.nestedCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (map['title'] != null) ...[
            Text(
              map['title'].toString().toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...displayEntries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textSecondary(context).withValues(alpha: 0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
