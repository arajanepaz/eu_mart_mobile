import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'feedback_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const EuMartFeedbackApp());
}

class EuMartFeedbackApp extends StatelessWidget {
  const EuMartFeedbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EÜ MART Customer Feedback',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const FeedbackScreen(),
    );
  }
}
