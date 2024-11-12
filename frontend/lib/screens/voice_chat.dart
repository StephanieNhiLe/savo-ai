import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';

class VoiceChat extends StatefulWidget {
  @override
  _VoiceChatState createState() => _VoiceChatState();
}

class _VoiceChatState extends State<VoiceChat> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isProcessing = false;
  String _userMessage = '';
  String _aiResponse = '';
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'done' && _userMessage.isNotEmpty) {
          _sendMessage(_userMessage);
        }
      },
      onError: (error) => print('Speech error: $error'),
    );
  }

  void _startListening() async {
    if (!_isListening && !_isProcessing) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _userMessage = '';
        });
        
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _userMessage = result.recognizedWords;
            });
            if (result.finalResult) {
              _stopListening();
            }
          },
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    if (_userMessage.isNotEmpty) {
      _sendMessage(_userMessage);
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    try { 
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _aiResponse = data['text'];
        });
 
        final audioResponse = await http.post(
          Uri.parse('http://127.0.0.1:5000/stream_audio'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'text': _aiResponse,
            'voice_id': 'EXAVITQu4vr4xnSDxMaL',
          }),
        );

        if (audioResponse.statusCode == 200) {
          final audioBytes = audioResponse.bodyBytes;
          await _audioPlayer.setAudioSource(
            AudioSource.uri(
              Uri.parse('data:audio/mpeg;base64,' + base64Encode(audioBytes)),
            ),
          );
          await _audioPlayer.play();
        } else {
          print('Failed to stream audio: ${audioResponse.statusCode}');
        }
      }
    } catch (e) {
      print('Exception occurred: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voice Chat')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_userMessage.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('You: $_userMessage'),
                      ),
                    ),
                  if (_aiResponse.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('AI: $_aiResponse'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : 
                           _isProcessing ? Colors.grey : Colors.blue,
                  ),
                  onPressed: _isProcessing ? null : _startListening,
                  iconSize: 64,
                ),
                SizedBox(height: 8),
                Text(
                  _isListening ? 'Listening...' : 
                  _isProcessing ? 'Processing...' : 'Tap to speak',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}