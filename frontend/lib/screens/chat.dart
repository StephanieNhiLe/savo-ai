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
  List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    // await _flutterTts.setSpeechRate(0.5);   
    // await _flutterTts.setPitch(1.1);      
    // await _flutterTts.setVolume(0.8);     
     
    var voices = await _flutterTts.getVoices;
    for (dynamic voice in voices) {
      // await flutterTts.setVoice({'name': 'en-us-x-iol-local', 'locale': 'en-US'});
      if (voice['name'].toString().toLowerCase().contains('samantha') ||
          voice['name'].toString().toLowerCase().contains('karen')) {
        await _flutterTts.setVoice(voice['name']);
        break;
      }
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': message});
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String aiResponse = data['response'];

        setState(() {
          _messages.add({'role': 'ai', 'content': aiResponse});
        });

        // await Future.delayed(Duration(milliseconds: 500));
        await _flutterTts.speak(aiResponse);
      } else {
        setState(() {
          _messages.add({
            'role': 'ai',
            'content': 'Sorry, I encountered an error. Please try again.'
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'content': 'Network error. Please check your connection.'
        });
      });
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('status: $status'),
      onError: (error) => print('error: $error'),
    );
    
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Card(
                  color: message['role'] == 'user' 
                    ? Colors.blue.shade50 
                    : Colors.green.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['role'] == 'user' ? 'You' : 'Safov AI',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          message['content']!,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              labelText: 'Type a message or use voice',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.red : Colors.grey,
                ),
                onPressed: _isListening ? _stopListening : _startListening,
              ),
            ),
            onSubmitted: (value) {
              _sendMessage(value);
              _controller.clear();
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}