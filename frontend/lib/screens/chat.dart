// frontend/lib/tabs/chat_tab.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatTab extends StatefulWidget {
  @override
  _ChatTabState createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _response = '';

  Future<void> _sendMessage(String message) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer YOUR_OPENAI_API_KEY',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [{'role': 'user', 'content': message}],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _response = data['choices'][0]['message']['content'];
      });
      await _flutterTts.speak(_response); // Convert text response to speech
    } else {
      // Handle error
      print('Error: ${response.statusCode}');
    }
  }

  void _startListening() async {
    await _speech.initialize();
    _speech.listen(onResult: (result) {
      setState(() {
        _controller.text = result.recognizedWords;
      });
    });
  }

  void _stopListening() {
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(_response), // Display AI response
              ],
            ),
          ),
        ),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Type a message or use voice',
            suffixIcon: IconButton(
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              onPressed: () {
                setState(() {
                  _isListening = !_isListening;
                  if (_isListening) {
                    _startListening();
                  } else {
                    _stopListening();
                  }
                });
              },
            ),
          ),
          onSubmitted: (value) {
            _sendMessage(value);
            _controller.clear();
          },
        ),
      ],
    );
  }
}