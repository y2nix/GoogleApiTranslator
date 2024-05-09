import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Импорт пакета для работы с Firebase Firestore.
import 'dart:convert';

class TranslationHistory {
  static final TranslationHistory _instance = TranslationHistory._internal();

  factory TranslationHistory() {
    return _instance;
  }

  TranslationHistory._internal();

  List<Map<String, String>> _history = [];
  FirebaseFirestore _firestore = FirebaseFirestore.instance; // Создание экземпляра Firestore.

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? history = prefs.getStringList('translation_history');
    if (history != null) {
      _history = history.map((entry) => Map<String, String>.from(json.decode(entry))).toList();
    }
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings = _history.map((entry) => json.encode(entry)).toList();
    await prefs.setStringList('translation_history', historyStrings);

    // Сохранение истории переводов в Firebase Firestore.
    for (var entry in _history) {
      await _firestore.collection('translation_history').add({
        'text': entry['text'],
        'sourceLanguage': entry['sourceLanguage'],
        'targetLanguage': entry['targetLanguage'],
        'translation': entry['translation'],
      });
    }
  }

  void addTranslation(String text, String sourceLanguage, String targetLanguage, String translation) {
    print('Adding translation to history: text: $text, source: $sourceLanguage, target: $targetLanguage, translation: $translation');
    final entry = {
      'text': text,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'translation': translation,
    };
    _history.add(entry);
    saveHistory();
  }

  List<Map<String, String>> get history => _history;
}