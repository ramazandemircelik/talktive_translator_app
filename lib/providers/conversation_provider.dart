import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';

enum ConversationMode { single, twoWay }

class ConversationProvider extends ChangeNotifier {
  late final SpeechService speechService;
  late final TranslationService translationService;
  late final TTSService ttsService;

  ConversationProvider() {
    speechService = SpeechService();
    translationService = TranslationService();
    ttsService = TTSService();
    _initializeServices();
  }

  // State
  final List<Message> _messages = [];
  String _sourceLanguage = 'en';
  String _targetLanguage = 'tr';
  MessageSpeaker _currentSpeaker = MessageSpeaker.user1;
  ConversationMode _conversationMode = ConversationMode.twoWay;
  bool _isProcessing = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String? _errorMessage;
  String _currentTranscription = '';

  StreamSubscription? _transcriptionSubscription;
  StreamSubscription? _listeningSubscription;
  StreamSubscription? _speakingSubscription;

  // Getters
  List<Message> get messages => List.unmodifiable(_messages);
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  MessageSpeaker get currentSpeaker => _currentSpeaker;
  ConversationMode get conversationMode => _conversationMode;
  bool get isProcessing => _isProcessing;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String? get errorMessage => _errorMessage;
  String get currentTranscription => _currentTranscription;

  void _initializeServices() async {
    await speechService.initialize();
    await ttsService.initialize();

    // Listen to speech recognition stream
    _transcriptionSubscription = speechService.transcriptionStream.listen(
      (transcription) {
        _currentTranscription = transcription;
        notifyListeners();
      },
    );

    // Listen to listening state
    _listeningSubscription = speechService.listeningStream.listen(
      (listening) {
        _isListening = listening;

        // Auto-process when listening stops in two-way mode
        if (!listening && _currentTranscription.isNotEmpty && !_isProcessing) {
          _processTranscription();
        }

        notifyListeners();
      },
    );

    // Listen to TTS speaking state
    _speakingSubscription = ttsService.speakingStream.listen(
      (speaking) {
        _isSpeaking = speaking;

        // In two-way mode, switch speaker when done speaking
        if (!speaking && _conversationMode == ConversationMode.twoWay) {
          _switchSpeaker();
        }

        notifyListeners();
      },
    );

    // Listen to errors
    speechService.errorStream.listen((error) {
      _errorMessage = error;
      notifyListeners();
    });

    ttsService.errorStream.listen((error) {
      _errorMessage = error;
      notifyListeners();
    });
  }

  void setLanguages(String source, String target) {
    _sourceLanguage = source;
    _targetLanguage = target;
    notifyListeners();
  }

  void swapLanguages() {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;
    notifyListeners();
  }

  void setConversationMode(ConversationMode mode) {
    _conversationMode = mode;
    notifyListeners();
  }

  void switchSpeaker() {
    _switchSpeaker();
  }

  void _switchSpeaker() {
    _currentSpeaker = _currentSpeaker == MessageSpeaker.user1
        ? MessageSpeaker.user2
        : MessageSpeaker.user1;
    notifyListeners();
  }

  Future<void> startListening() async {
    _errorMessage = null;
    _currentTranscription = '';

    final currentLang = _getCurrentLanguage();
    await speechService.startListening(languageCode: currentLang);
  }

  Future<void> stopListening() async {
    await speechService.stopListening();
    if (_currentTranscription.isNotEmpty && !_isProcessing) {
      await _processTranscription();
    }
  }

  Future<void> _processTranscription() async {
    if (_currentTranscription.isEmpty || _isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final originalText = _currentTranscription;
      final currentLang = _getCurrentLanguage();
      final targetLang = _getTargetLanguage();

      // Create processing message
      final message = Message(
        originalText: originalText,
        translatedText: '',
        originalLanguage: currentLang,
        targetLanguage: targetLang,
        speaker: _currentSpeaker,
        isProcessing: true,
      );

      _messages.add(message);
      notifyListeners();

      // Translate
      final translatedText = await translationService.translate(
        text: originalText,
        sourceLanguage: currentLang,
        targetLanguage: targetLang,
      );

      // Update message with translation
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[index] = message.copyWith(
          translatedText: translatedText,
          isProcessing: false,
        );
        notifyListeners();
      }

      // Speak the translation
      await ttsService.speak(
        text: translatedText,
        languageCode: targetLang,
      );

      _currentTranscription = '';
    } catch (e) {
      _errorMessage = 'Translation failed: $e';
      debugPrint('Error processing transcription: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  String _getCurrentLanguage() {
    if (_currentSpeaker == MessageSpeaker.user1) {
      return _sourceLanguage;
    } else {
      return _targetLanguage;
    }
  }

  String _getTargetLanguage() {
    if (_currentSpeaker == MessageSpeaker.user1) {
      return _targetLanguage;
    } else {
      return _sourceLanguage;
    }
  }

  Future<void> toggleListening() async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> setTTSVoiceGender(TTSVoiceGender gender) async {
    await ttsService.setVoiceGender(gender);
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    await ttsService.setSpeechRate(rate);
  }

  Future<void> setPitch(double pitch) async {
    await ttsService.setPitch(pitch);
  }

  // Manual message sending (for testing or typing)
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final currentLang = _getCurrentLanguage();
      final targetLang = _getTargetLanguage();

      final message = Message(
        originalText: text,
        translatedText: '',
        originalLanguage: currentLang,
        targetLanguage: targetLang,
        speaker: _currentSpeaker,
        isProcessing: true,
      );

      _messages.add(message);
      notifyListeners();

      final translatedText = await translationService.translate(
        text: text,
        sourceLanguage: currentLang,
        targetLanguage: targetLang,
      );

      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[index] = message.copyWith(
          translatedText: translatedText,
          isProcessing: false,
        );
        notifyListeners();
      }

      await ttsService.speak(
        text: translatedText,
        languageCode: targetLang,
      );

      if (_conversationMode == ConversationMode.twoWay) {
        _switchSpeaker();
      }
    } catch (e) {
      _errorMessage = 'Failed to send message: $e';
      debugPrint('Error sending message: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _transcriptionSubscription?.cancel();
    _listeningSubscription?.cancel();
    _speakingSubscription?.cancel();
    super.dispose();
  }
}
