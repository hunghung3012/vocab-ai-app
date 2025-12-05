import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vocab_ai/main_screen.dart';
import 'package:vocab_ai/services/local_notification/local_notification_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/docks/create_deck/create_deck_screen.dart';
import 'screens/docks/study_screen.dart';
import 'screens/docks/edit_deck_screen.dart';
import 'screens/chat_ai/chat_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/docks/import_anki_screen.dart';
import 'models/deck.dart';
import 'firebase_options.dart';
import 'screens/docks/decks_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.signInAnonymously();

  // ✅ THÊM: Initialize notification service
  await _initializeNotifications();

  runApp(const VocabAIApp());
}

// ✅ THÊM: Function để initialize notifications
Future<void> _initializeNotifications() async {
  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  // Schedule daily reminder at 8 AM
  await notificationService.scheduleDailyVocabReminder();

  // 🧪 TESTING: Uncomment để test notification mỗi 20 giây
  // await notificationService.startRepeatingNotificationEvery20Seconds();
}

class VocabAIApp extends StatelessWidget {
  const VocabAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VocabAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Inter',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const MainScreen(initialIndex: 0),
            );
          case '/dashboard':
            return MaterialPageRoute(
              builder: (_) => const MainScreen(initialIndex: 1),
            );
          case '/decks':
            return MaterialPageRoute(
              builder: (_) => const MainScreen(initialIndex: 2),
            );
          case '/quiz':
            final deck = settings.arguments as Deck?;
            if (deck != null) {
              return MaterialPageRoute(builder: (_) => QuizScreen(deck: deck));
            }
            return MaterialPageRoute(
              builder: (_) => const MainScreen(initialIndex: 3),
            );
          case '/chat':
            return MaterialPageRoute(
              builder: (_) => const MainScreen(initialIndex: 4),
            );
          case '/create-deck':
            return MaterialPageRoute(
              builder: (_) => const CreateDeckScreen(),
            );
          case '/study':
            final deck = settings.arguments as Deck;
            return MaterialPageRoute(
              builder: (_) => StudyScreen(deck: deck),
            );
          case '/edit-deck':
            final deck = settings.arguments as Deck;
            return MaterialPageRoute(
              builder: (_) => EditDeckScreen(deck: deck),
            );
          case '/import-anki':
            return MaterialPageRoute(
              builder: (_) => const ImportAnkiScreen(),
            );
          case '/quiz-with-deck':
            final deck = settings.arguments as Deck;
            return MaterialPageRoute(
              builder: (_) => QuizScreen(deck: deck),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const MainScreen(initialIndex: 0),
            );
        }
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MainScreen(initialIndex: 0);
  }
}