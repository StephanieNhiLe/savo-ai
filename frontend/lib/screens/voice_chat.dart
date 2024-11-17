import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String _sentimentAnalysisResult = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _conversationId = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _conversationId = _firestore.collection('conversations').doc().id;
  }

  void _initializeSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'done' && _userMessage.isNotEmpty) {
          _sendMessage(_userMessage, _conversationId);
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
              _sendMessage(_userMessage, _conversationId);
              _stopListening();
            }
          },
          listenFor: Duration(seconds: 60),
          pauseFor: Duration(seconds: 10),
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
  }


  Future<void> _sendMessage(String message, String conversationId) async {
    if (message.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    try {
        String sentiment = 'neutral';
        double sentimentScore = 0.0; 
        try {
            final sentimentResponse = await http.post(
                Uri.parse('http://127.0.0.1:5000/analyze_sentiment'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                    'text': message,
                }),
            );

            if (sentimentResponse.statusCode == 200) {
                final sentimentData = json.decode(sentimentResponse.body);
                sentiment = sentimentData['sentiment'] ?? 'neutral';
                sentimentScore = sentimentData['score'] ?? 0.0; 
            }
        } catch (e) {
            print('Sentiment analysis error: $e');
        }

        setState(() {
            _sentimentAnalysisResult = sentiment;
        });

        final response = await http.post(
            Uri.parse('http://127.0.0.1:5000/chat'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
                'message': message,
            }),
        );

        if (response.statusCode == 200) {
            final data = json.decode(response.body);
            String aiResponse = data['text'].replaceAll('"', '');
            setState(() {
                _aiResponse = aiResponse;
            });

            await _pushUserMessageToFirestore(message, sentiment, sentimentScore, conversationId);
            await _pushAIResponseToFirestore(aiResponse, conversationId);
        }
    } catch (e) {
        print('Exception occurred: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('An error occurred while processing your message'),
                backgroundColor: Colors.red,
            ),
        );
    } finally {
        setState(() => _isProcessing = false);
    }
}

Future<void> _pushUserMessageToFirestore(String message, String sentiment, double sentimentScore, String conversationId) async {
    if (message.trim().isEmpty) return;

    try {
        String userId = 'user@example.com';
        Timestamp createdAt = Timestamp.now();
        Timestamp lastUpdated = Timestamp.now();
        String title = 'Voice Chat';
        String status = 'closed';

        DocumentReference conversationRef = _firestore.collection('conversations').doc(conversationId);
        DocumentSnapshot conversationSnapshot = await conversationRef.get();
        if (!conversationSnapshot.exists) {
            await conversationRef.set({
                'userId': userId,
                'createdAt': createdAt,
                'lastUpdated': lastUpdated,
                'title': title,
                'status': status,
            });
        }

        await conversationRef.collection('messages').add({
            'sender': 'user',
            'content': message,
            'timestamp': Timestamp.now(),
            'type': 'text',
            'metadata': {
                'sentiment': sentiment, 
                'sentimentScore': sentimentScore, 
            },
        });
        print('User message saved successfully.');

    } catch (e) {
        print('Error saving user message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to save user message: $e'),
                backgroundColor: Colors.red,
            ),
        );
    }
}

Future<void> _pushAIResponseToFirestore(String aiResponse, String conversationId) async {
    try {
        await _firestore.collection('conversations').doc(conversationId).collection('messages').add({
            'sender': 'ai',
            'content': aiResponse,
            'timestamp': Timestamp.now(),
            'type': 'text',
            'metadata': {},
        });
        print('AI response saved successfully.');
    } catch (e) {
        print('Error saving AI response: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to save AI response: $e'),
                backgroundColor: Colors.red,
            ),
        );
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
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    Text('You: $_userMessage'),
                                                    SizedBox(height: 8),
                                                    Row(
                                                        children: [
                                                            Icon(
                                                                _getSentimentIcon(_sentimentAnalysisResult),
                                                                color: _getSentimentColor(_sentimentAnalysisResult),
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                                'Sentiment: $_sentimentAnalysisResult',
                                                                style: TextStyle(
                                                                    color: _getSentimentColor(_sentimentAnalysisResult),
                                                                    fontWeight: FontWeight.bold,
                                                                ),
                                                            ),
                                                        ],
                                                    ),
                                                ],
                                            ),
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

IconData _getSentimentIcon(String sentiment) {
    switch (sentiment.toLowerCase()) {
        case 'very positive':
            return Icons.sentiment_very_satisfied;
        case 'positive':
            return Icons.sentiment_satisfied;
        case 'neutral':
            return Icons.sentiment_neutral;
        case 'negative':
            return Icons.sentiment_dissatisfied;
        case 'very negative':
            return Icons.sentiment_very_dissatisfied;
        default:
            return Icons.sentiment_neutral;
    }
}

Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
        case 'very positive':
            return Colors.lightGreen;
        case 'positive':
            return Colors.green;
        case 'neutral':
            return Colors.grey;
        case 'negative':
            return Colors.red;
        case 'very negative':
            return Colors.deepOrange;
        default:
            return Colors.grey;
    }
}
}