import 'package:uuid/uuid.dart';

enum MessageSpeaker { user1, user2 }

class Message {
  final String id;
  final String originalText;
  final String translatedText;
  final String originalLanguage;
  final String targetLanguage;
  final MessageSpeaker speaker;
  final DateTime timestamp;
  final bool isProcessing;

  Message({
    String? id,
    required this.originalText,
    required this.translatedText,
    required this.originalLanguage,
    required this.targetLanguage,
    required this.speaker,
    DateTime? timestamp,
    this.isProcessing = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Message copyWith({
    String? originalText,
    String? translatedText,
    String? originalLanguage,
    String? targetLanguage,
    MessageSpeaker? speaker,
    DateTime? timestamp,
    bool? isProcessing,
  }) {
    return Message(
      id: id,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      speaker: speaker ?? this.speaker,
      timestamp: timestamp ?? this.timestamp,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'originalLanguage': originalLanguage,
      'targetLanguage': targetLanguage,
      'speaker': speaker == MessageSpeaker.user1 ? 'user1' : 'user2',
      'timestamp': timestamp.toIso8601String(),
      'isProcessing': isProcessing,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      originalText: json['originalText'],
      translatedText: json['translatedText'],
      originalLanguage: json['originalLanguage'],
      targetLanguage: json['targetLanguage'],
      speaker: json['speaker'] == 'user1'
          ? MessageSpeaker.user1
          : MessageSpeaker.user2,
      timestamp: DateTime.parse(json['timestamp']),
      isProcessing: json['isProcessing'] ?? false,
    );
  }
}
