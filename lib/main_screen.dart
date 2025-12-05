import 'package:flutter/material.dart';
import 'package:vocab_ai/screens/chat_ai/chat_screen.dart';
import 'package:vocab_ai/screens/dashboard/dashboard_screen.dart';
import 'package:vocab_ai/screens/docks/decks_screen.dart';
import 'package:vocab_ai/screens/home/home_screen.dart';
import 'package:vocab_ai/screens/quiz/quiz_screen.dart';
import 'package:vocab_ai/screens/settings/setting_screen.dart';
import '../widgets/app_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  // 🔥 Danh sách các màn hình chính
  final List<Widget> _pages = [
    const HomeScreen(),
    const DashboardScreen(),
    const DecksScreen(),
    const QuizScreen(deck: null), // Quiz list - không có deck cụ thể
    const ChatScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      // 🔥 AppBar cố định cho tất cả tabs
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.book, color: Colors.white),
          ),
        ),
        title: const Text(
          'VocabAI',
          style: TextStyle(
            color: Colors.purple,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),
        ],
      ),

      // 🔥 Body - Chuyển đổi giữa các trang
      // IndexedStack giữ state của mỗi trang khi chuyển tab
      body: IndexedStack(index: _currentIndex, children: _pages),

      // 🔥 BottomNavigationBar cố định
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
