import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TTSVoiceGender { male, female, neutral }

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  TTSVoiceGender _voiceGender = TTSVoiceGender.female;

  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<bool> get speakingStream => _speakingController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  TTSVoiceGender get voiceGender => _voiceGender;

  Future<void> initialize() async {
    try {
      // Set up handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _speakingController.add(true);
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakingController.add(false);
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _speakingController.add(false);
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _errorController.add('TTS Error: $msg');
        _isSpeaking = false;
        _speakingController.add(false);
      });

      // Set default configuration
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);

      // Platform-specific settings
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      _errorController.add('Failed to initialize TTS: $e');
    }
  }

  Future<void> speak({
    required String text,
    required String languageCode,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.trim().isEmpty) {
      return;
    }

    try {
      // Stop any ongoing speech
      if (_isSpeaking) {
        await stop();
      }

      // Set language
      await _flutterTts.setLanguage(_getLanguageCode(languageCode));

      // Set voice based on gender preference
      await _setVoiceByGender(languageCode, _voiceGender);

      // Speak the text
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
      _errorController.add('Failed to speak: $e');
      _isSpeaking = false;
      _speakingController.add(false);
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _speakingController.add(false);
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('Error pausing TTS: $e');
    }
  }

  Future<void> setVoiceGender(TTSVoiceGender gender) async {
    _voiceGender = gender;
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      debugPrint('Error setting speech rate: $e');
    }
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      debugPrint('Error setting pitch: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  String _getLanguageCode(String code) {
    // Map language codes to TTS-compatible codes
    final languageMap = {
      'en': 'en-US',
      'tr': 'tr-TR',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'it': 'it-IT',
      'pt': 'pt-PT',
      'ru': 'ru-RU',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'zh': 'zh-CN',
      'ar': 'ar-SA',
      'hi': 'hi-IN',
      'nl': 'nl-NL',
      'pl': 'pl-PL',
    };

    return languageMap[code] ?? 'en-US';
  }

  Future<void> _setVoiceByGender(
      String languageCode, TTSVoiceGender gender) async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices == null || voices.isEmpty) return;

      final langCode = _getLanguageCode(languageCode);

      // Filter voices by language
      final languageVoices = (voices as List).where((voice) {
        final voiceMap = voice as Map<dynamic, dynamic>;
        final name = voiceMap['name']?.toString().toLowerCase() ?? '';
        final locale = voiceMap['locale']?.toString().toLowerCase() ?? '';
        return locale.contains(languageCode) || name.contains(languageCode);
      }).toList();

      if (languageVoices.isEmpty) return;

      // Try to find a voice matching the gender preference
      Map<dynamic, dynamic>? selectedVoice;

      for (final voice in languageVoices) {
        final voiceMap = voice as Map<dynamic, dynamic>;
        final name = voiceMap['name']?.toString().toLowerCase() ?? '';

        if (gender == TTSVoiceGender.female &&
            (name.contains('female') ||
                name.contains('woman') ||
                name.contains('samantha'))) {
          selectedVoice = voiceMap;
          break;
        } else if (gender == TTSVoiceGender.male &&
            (name.contains('male') ||
                name.contains('man') ||
                name.contains('aaron'))) {
          selectedVoice = voiceMap;
          break;
        }
      }

      // If no gender-specific voice found, use the first available
      selectedVoice ??= languageVoices.first as Map<dynamic, dynamic>;

      await _flutterTts.setVoice({
        'name': selectedVoice['name'],
        'locale': selectedVoice['locale'],
      });
    } catch (e) {
      debugPrint('Error setting voice: $e');
    }
  }

  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices == null) return [];

      return (voices as List).map((voice) {
        final voiceMap = voice as Map<dynamic, dynamic>;
        return {
          'name': voiceMap['name']?.toString() ?? '',
          'locale': voiceMap['locale']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting available voices: $e');
      return [];
    }
  }

  void dispose() {
    _flutterTts.stop();
    _speakingController.close();
    _errorController.close();
  }
}
