import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TranslationService {
  // NOTE: In production, use environment variables or secure storage for API keys
  // For this demo, you'll need to add your own API key
  static const String _googleTranslateApiKey = 'YOUR_GOOGLE_TRANSLATE_API_KEY';
  static const String _baseUrl =
      'https://translation.googleapis.com/language/translate/v2';

  // Alternative: Use LibreTranslate (free, self-hosted or public instance)
  static const String _libreTranslateUrl =
      'https://libretranslate.com/translate';

  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (text.trim().isEmpty) {
      return '';
    }

    try {
      // Try Google Translate first (if API key is provided)
      if (_googleTranslateApiKey != 'YOUR_GOOGLE_TRANSLATE_API_KEY') {
        return await _translateWithGoogle(text, sourceLanguage, targetLanguage);
      } else {
        // Fallback to LibreTranslate (free alternative)
        return await _translateWithLibre(text, sourceLanguage, targetLanguage);
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      // Return original text if translation fails
      return text;
    }
  }

  Future<String> _translateWithGoogle(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    final url = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'key': _googleTranslateApiKey,
        'q': text,
        'source': sourceLanguage,
        'target': targetLanguage,
        'format': 'text',
      },
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['translations'][0]['translatedText'];
    } else {
      throw Exception('Translation failed: ${response.statusCode}');
    }
  }

  Future<String> _translateWithLibre(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    final url = Uri.parse(_libreTranslateUrl);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'q': text,
        'source': sourceLanguage,
        'target': targetLanguage,
        'format': 'text',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['translatedText'];
    } else {
      throw Exception('Translation failed: ${response.statusCode}');
    }
  }

  // Detect language (if needed)
  Future<String> detectLanguage(String text) async {
    if (text.trim().isEmpty) {
      return 'en';
    }

    try {
      if (_googleTranslateApiKey != 'YOUR_GOOGLE_TRANSLATE_API_KEY') {
        return await _detectWithGoogle(text);
      } else {
        return await _detectWithLibre(text);
      }
    } catch (e) {
      debugPrint('Language detection error: $e');
      return 'en'; // Default to English
    }
  }

  Future<String> _detectWithGoogle(String text) async {
    final url = Uri.parse('$_baseUrl/detect').replace(
      queryParameters: {
        'key': _googleTranslateApiKey,
        'q': text,
      },
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['detections'][0][0]['language'];
    } else {
      throw Exception('Language detection failed: ${response.statusCode}');
    }
  }

  Future<String> _detectWithLibre(String text) async {
    final url = Uri.parse('https://libretranslate.com/detect');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'q': text}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        return data[0]['language'];
      }
      return 'en';
    } else {
      throw Exception('Language detection failed: ${response.statusCode}');
    }
  }

  // Batch translation for multiple texts
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final translations = <String>[];

    for (final text in texts) {
      final translation = await translate(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      translations.add(translation);
    }

    return translations;
  }
}
