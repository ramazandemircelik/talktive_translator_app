import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();
  final StreamController<bool> _listeningController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _errorController.add('Microphone permission denied');
        return false;
      }

      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: ${error.errorMsg}');
          _errorController.add('Speech recognition error: ${error.errorMsg}');
          _isListening = false;
          _listeningController.add(false);
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _listeningController.add(false);
          }
        },
      );

      if (!_isInitialized) {
        _errorController.add('Failed to initialize speech recognition');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing speech service: $e');
      _errorController.add('Failed to initialize: $e');
      return false;
    }
  }

  Future<void> startListening({required String languageCode}) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _transcriptionController.add(result.recognizedWords);
          }
        },
        localeId: _getLocaleId(languageCode),
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
        onSoundLevelChange: (level) {
          // Can be used for visual feedback
        },
      );

      _isListening = true;
      _listeningController.add(true);
    } catch (e) {
      debugPrint('Error starting listening: $e');
      _errorController.add('Failed to start listening: $e');
      _isListening = false;
      _listeningController.add(false);
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      _listeningController.add(false);
    } catch (e) {
      debugPrint('Error stopping listening: $e');
      _errorController.add('Failed to stop listening: $e');
    }
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
      _isListening = false;
      _listeningController.add(false);
    } catch (e) {
      debugPrint('Error cancelling speech recognition: $e');
    }
  }

  String _getLocaleId(String languageCode) {
    // Map language codes to locale IDs for speech recognition
    final localeMap = {
      'en': 'en_US',
      'tr': 'tr_TR',
      'es': 'es_ES',
      'fr': 'fr_FR',
      'de': 'de_DE',
      'it': 'it_IT',
      'pt': 'pt_PT',
      'ru': 'ru_RU',
      'ja': 'ja_JP',
      'ko': 'ko_KR',
      'zh': 'zh_CN',
      'ar': 'ar_SA',
      'hi': 'hi_IN',
      'nl': 'nl_NL',
      'pl': 'pl_PL',
    };

    return localeMap[languageCode] ?? 'en_US';
  }

  Future<List<String>> getAvailableLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final locales = await _speech.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      debugPrint('Error getting available languages: $e');
      return [];
    }
  }

  void dispose() {
    _speech.stop();
    _transcriptionController.close();
    _listeningController.close();
    _errorController.close();
  }
}
