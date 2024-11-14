import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'conversation_model.dart';

class ConversationRepository {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'conversations.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE conversations(
            id TEXT PRIMARY KEY,
            startTime TEXT,
            endTime TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            conversationId TEXT,
            content TEXT,
            isUser INTEGER,
            timestamp TEXT,
            sentiment TEXT,
            FOREIGN KEY(conversationId) REFERENCES conversations(id)
          )
        ''');
      },
    );
  }

  Future<String> startNewConversation() async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('conversations', {
      'id': id,
      'startTime': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<void> addMessage(String conversationId, Message message) async {
    final db = await database;
    await db.insert('messages', {
      'id': message.id,
      'conversationId': conversationId,
      'content': message.content,
      'isUser': message.isUser ? 1 : 0,
      'timestamp': message.timestamp.toIso8601String(),
      'sentiment': message.sentiment != null ? jsonEncode(message.sentiment) : null,
    });
  }

  Future<List<Message>> getConversationMessages(String conversationId) async {
    final db = await database;
    final messages = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return messages.map((m) => Message.fromJson(m)).toList();
  }
} 