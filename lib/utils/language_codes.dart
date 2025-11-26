class LanguageCode {
  final String code;
  final String name;
  final String flag;

  const LanguageCode({
    required this.code,
    required this.name,
    required this.flag,
  });
}

class LanguageCodes {
  static const List<LanguageCode> supportedLanguages = [
    LanguageCode(code: 'en', name: 'English', flag: '🇬🇧'),
    LanguageCode(code: 'tr', name: 'Turkish', flag: '🇹🇷'),
    LanguageCode(code: 'es', name: 'Spanish', flag: '🇪🇸'),
    LanguageCode(code: 'fr', name: 'French', flag: '🇫🇷'),
    LanguageCode(code: 'de', name: 'German', flag: '🇩🇪'),
    LanguageCode(code: 'it', name: 'Italian', flag: '🇮🇹'),
    LanguageCode(code: 'pt', name: 'Portuguese', flag: '🇵🇹'),
    LanguageCode(code: 'ru', name: 'Russian', flag: '🇷🇺'),
    LanguageCode(code: 'ja', name: 'Japanese', flag: '🇯🇵'),
    LanguageCode(code: 'ko', name: 'Korean', flag: '🇰🇷'),
    LanguageCode(code: 'zh', name: 'Chinese', flag: '🇨🇳'),
    LanguageCode(code: 'ar', name: 'Arabic', flag: '🇸🇦'),
    LanguageCode(code: 'hi', name: 'Hindi', flag: '🇮🇳'),
    LanguageCode(code: 'nl', name: 'Dutch', flag: '🇳🇱'),
    LanguageCode(code: 'pl', name: 'Polish', flag: '🇵🇱'),
  ];

  static LanguageCode getLanguageByCode(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => supportedLanguages[0], // Default to English
    );
  }

  static String getLanguageName(String code) {
    return getLanguageByCode(code).name;
  }

  static String getLanguageFlag(String code) {
    return getLanguageByCode(code).flag;
  }
}
