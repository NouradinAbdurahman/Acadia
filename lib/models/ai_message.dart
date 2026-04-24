import 'package:flutter/material.dart';

class AiMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String type;
  final dynamic data;
  final String? intent;
  final Map<String, dynamic>? summaryMetadata;
  final List<String>? suggestions;
  final String? semesterId;
  final GlobalKey key = GlobalKey();
  String displayedText;

  AiMessage({
    required this.text,
    required this.isUser,
    this.type = 'text',
    this.data,
    this.intent,
    this.summaryMetadata,
    this.suggestions,
    this.semesterId,
    this.displayedText = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now() {
    // If it's a user message, show it immediately
    if (isUser) {
      displayedText = text;
    }
  }

  Map<String, dynamic> toJson() => {
        'role': isUser ? 'user' : 'assistant',
        'content': text,
      };

  AiMessage copyWith({
    String? displayedText,
    String? semesterId,
  }) {
    return AiMessage(
      text: text,
      isUser: isUser,
      type: type,
      data: data,
      intent: intent,
      summaryMetadata: summaryMetadata,
      suggestions: suggestions,
      semesterId: semesterId ?? this.semesterId,
      displayedText: displayedText ?? this.displayedText,
      timestamp: timestamp,
    );
  }
}
