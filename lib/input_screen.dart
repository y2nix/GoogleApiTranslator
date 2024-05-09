import 'package:flutter/material.dart';
import 'translation_history.dart';
import 'api_keys.dart'; // Импорт файла с ключом API
import 'package:http/http.dart' as http;
import 'dart:convert';

class InputScreen extends StatefulWidget {
  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  String _selectedSourceLanguage = 'en';
  String _selectedTargetLanguage = 'ru';
  String _translatedText = '';
  TranslationHistory _historyManager = TranslationHistory();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await _historyManager.loadHistory();
  }

  Future<void> _translate(String text, String sourceLanguage, String targetLanguage) async {
    try {
      final url = 'https://translation.googleapis.com/language/translate/v2?key=$googleTranslateApiKey&source=$sourceLanguage&target=$targetLanguage&q=$text';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _translatedText = data['data']['translations'][0]['translatedText'];
        });
        _historyManager.addTranslation(text, sourceLanguage, targetLanguage, _translatedText);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load translation'),
        ));
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred during translation'),
      ));
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _selectedSourceLanguage;
      _selectedSourceLanguage = _selectedTargetLanguage;
      _selectedTargetLanguage = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Translator'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TranslationHistoryScreen(history: _historyManager.history),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _textEditingController,
              decoration: InputDecoration(
                labelText: 'Enter text',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<String>(
                value: _selectedSourceLanguage,
                items: [
                  DropdownMenuItem(child: Text('English'), value: 'en'),
                  DropdownMenuItem(child: Text('Russian'), value: 'ru'),
                  DropdownMenuItem(child: Text('Spanish'), value: 'es'),
                  DropdownMenuItem(child: Text('French'), value: 'fr'),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSourceLanguage = value!;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.compare_arrows),
                onPressed: _swapLanguages,
              ),
              DropdownButton<String>(
                value: _selectedTargetLanguage,
                items: [
                  DropdownMenuItem(child: Text('Russian'), value: 'ru'),
                  DropdownMenuItem(child: Text('English'), value: 'en'),
                  DropdownMenuItem(child: Text('Spanish'), value: 'es'),
                  DropdownMenuItem(child: Text('French'), value: 'fr'),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTargetLanguage = value!;
                  });
                },
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              final originalText = _textEditingController.text;
              _translate(originalText, _selectedSourceLanguage, _selectedTargetLanguage);
            },
            child: Text('Translate'),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Translation:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _translatedText,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TranslationHistoryScreen extends StatelessWidget {
  final List<Map<String, String>> history;

  TranslationHistoryScreen({required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Translation History'),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('${history[index]['text']} (${history[index]['sourceLanguage']} -> ${history[index]['targetLanguage']}) - ${history[index]['translation']}'),
          );
        },
      ),
    );
  }
}