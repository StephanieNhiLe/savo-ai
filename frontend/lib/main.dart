import 'package:flutter/material.dart';
import 'screens/chat.dart';
import 'screens/location_sharing.dart';
import 'screens/mood_tracker.dart';
import 'screens/voice_chat.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'models/circles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.web,  
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Savo AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Savo AI',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: TabBarView(
          children: [
            VoiceChat(),  
            CirclesScreen(),
            MoodTracker(),
          ],
        ),
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(text: 'Voice Chat', icon: Icon(Icons.mic)),
            Tab(text: 'Location Sharing', icon: Icon(Icons.location_on)),
            Tab(text: 'Mood Tracker', icon: Icon(Icons.mood)),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
    );
  }
}
