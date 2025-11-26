import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversation_provider.dart';
import '../widgets/language_picker.dart';
import '../widgets/mic_button.dart';
import '../widgets/message_bubble.dart';
import '../models/message_model.dart';
import '../services/tts_service.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showSettings = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Translator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_showSettings ? Icons.close : Icons.settings),
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
          Consumer<ConversationProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () {
                      provider.clearMessages();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Clear Chat'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () {
                      provider.switchSpeaker();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.swap_horiz),
                        SizedBox(width: 8),
                        Text('Switch Speaker'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Consumer<ConversationProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: LanguagePicker(
                        selectedLanguage: provider.sourceLanguage,
                        onLanguageChanged: (lang) {
                          provider.setLanguages(lang, provider.targetLanguage);
                        },
                        label: 'From',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        onPressed: () {
                          provider.swapLanguages();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: LanguagePicker(
                        selectedLanguage: provider.targetLanguage,
                        onLanguageChanged: (lang) {
                          provider.setLanguages(provider.sourceLanguage, lang);
                        },
                        label: 'To',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: Column(
        children: [
          if (_showSettings) _buildSettingsPanel(),
          Expanded(
            child: Consumer<ConversationProvider>(
              builder: (context, provider, child) {
                // Auto-scroll when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (provider.messages.isNotEmpty) {
                    _scrollToBottom();
                  }
                });

                if (provider.messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    final isCurrentUser =
                        message.speaker == provider.currentSpeaker;
                    return MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                );
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Consumer<ConversationProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.volume_up, size: 20),
                  const SizedBox(width: 12),
                  const Text('Voice Gender:'),
                  const Spacer(),
                  SegmentedButton<TTSVoiceGender>(
                    segments: const [
                      ButtonSegment(
                        value: TTSVoiceGender.female,
                        label: Text('Female'),
                      ),
                      ButtonSegment(
                        value: TTSVoiceGender.male,
                        label: Text('Male'),
                      ),
                    ],
                    selected: {provider.ttsService.voiceGender},
                    onSelectionChanged: (Set<TTSVoiceGender> selection) {
                      provider.setTTSVoiceGender(selection.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.speed, size: 20),
                  const SizedBox(width: 12),
                  const Text('Speech Rate:'),
                  Expanded(
                    child: Slider(
                      value: 0.5,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: '0.5x',
                      onChanged: (value) {
                        provider.setSpeechRate(value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.translate,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a Conversation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Tap the microphone to start speaking.\nYour words will be translated in real-time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<ConversationProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error message display
                if (provider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: provider.clearError,
                          color: Colors.red.shade700,
                        ),
                      ],
                    ),
                  ),
                ],

                // Current transcription display
                if (provider.isListening &&
                    provider.currentTranscription.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mic,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.currentTranscription,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Status indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (provider.isListening)
                      _buildStatusChip(
                        context,
                        'Listening...',
                        Icons.mic,
                        Colors.red,
                      )
                    else if (provider.isSpeaking)
                      _buildStatusChip(
                        context,
                        'Speaking...',
                        Icons.volume_up,
                        Colors.blue,
                      )
                    else if (provider.isProcessing)
                      _buildStatusChip(
                        context,
                        'Processing...',
                        Icons.translate,
                        Colors.orange,
                      )
                    else
                      _buildStatusChip(
                        context,
                        'Ready',
                        Icons.check_circle,
                        Colors.green,
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Microphone button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MicButton(
                      isListening: provider.isListening,
                      isProcessing: provider.isProcessing,
                      onPressed: provider.toggleListening,
                      onLongPress: provider.startListening,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Instruction text
                Text(
                  provider.isListening
                      ? 'Tap to stop • Speak clearly'
                      : 'Tap to speak • Hold for continuous',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),

                const SizedBox(height: 8),

                // Current speaker indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Speaker ${provider.currentSpeaker == MessageSpeaker.user1 ? "1" : "2"}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
