import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/message_model.dart';
import '../utils/language_codes.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final originalLang =
        LanguageCodes.getLanguageByCode(message.originalLanguage);
    final targetLang = LanguageCodes.getLanguageByCode(message.targetLanguage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                '2',
                style: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCurrentUser
                      ? [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primaryContainer.withOpacity(0.8),
                        ]
                      : [
                          theme.colorScheme.secondaryContainer,
                          theme.colorScheme.secondaryContainer.withOpacity(0.8),
                        ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original text with language flag
                  Row(
                    children: [
                      Text(
                        originalLang.flag,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          message.originalText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isCurrentUser
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (message.isProcessing) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SpinKitThreeBounce(
                          color: isCurrentUser
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSecondaryContainer,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Translating...',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: (isCurrentUser
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSecondaryContainer)
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ] else if (message.translatedText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Divider(
                      color: (isCurrentUser
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSecondaryContainer)
                          .withOpacity(0.2),
                      height: 1,
                    ),
                    const SizedBox(height: 8),
                    // Translated text with language flag
                    Row(
                      children: [
                        Text(
                          targetLang.flag,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            message.translatedText,
                            style: TextStyle(
                              fontSize: 14,
                              color: (isCurrentUser
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSecondaryContainer)
                                  .withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 4),
                  // Timestamp
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: (isCurrentUser
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSecondaryContainer)
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '1',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
