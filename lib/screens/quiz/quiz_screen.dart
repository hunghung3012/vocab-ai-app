import 'package:flutter/material.dart';
import '../../models/deck.dart';
import '../../services/firebase_service.dart';
import 'quiz_type_selection_screen.dart';
import 'widgets/quiz_deck_card.dart';

class QuizScreen extends StatefulWidget {
  final Deck? deck;

  const QuizScreen({Key? key, this.deck}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Deck> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.deck != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showQuizTypeSelection(widget.deck!);
      });
    } else {
      _loadDecks();
    }
  }

  Future<void> _loadDecks() async {
    try {
      final decks = await _firebaseService.getDecksStream().first;
      if (mounted) {
        setState(() {
          _decks = decks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading decks: $e')),
      );
    }
  }

  void _showQuizTypeSelection(Deck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizTypeSelectionScreen(deck: deck),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deck != null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _decks.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Take a Quiz',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test your knowledge with interactive quizzes',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Select a Deck',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._decks.map((deck) => QuizDeckCard(
                deck: deck,
                onTap: () => _showQuizTypeSelection(deck),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 64,
                color: Colors.purple.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No decks available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a deck first to start taking quizzes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create-deck');
              },
              icon: const Icon(Icons.add, size: 24),
              label: const Text('Create Deck', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}