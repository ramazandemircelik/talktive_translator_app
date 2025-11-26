import 'package:flutter/material.dart';
import '../utils/language_codes.dart';

class LanguagePicker extends StatelessWidget {
  final String selectedLanguage;
  final Function(String) onLanguageChanged;
  final String label;

  const LanguagePicker({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLang = LanguageCodes.getLanguageByCode(selectedLanguage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLanguage,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          items: LanguageCodes.supportedLanguages.map((lang) {
            return DropdownMenuItem<String>(
              value: lang.code,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lang.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onLanguageChanged(value);
            }
          },
          selectedItemBuilder: (context) {
            return LanguageCodes.supportedLanguages.map((lang) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lang.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
