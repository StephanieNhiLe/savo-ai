class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? sentiment;

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.sentiment,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'sentiment': sentiment,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    content: json['content'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
    sentiment: json['sentiment'],
  );
}

class Conversation {
  final String id;
  final List<Message> messages;
  final DateTime startTime;
  final DateTime? endTime;

  Conversation({
    required this.id,
    required this.messages,
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'messages': messages.map((m) => m.toJson()).toList(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
  };
} 