import 'package:flutter/material.dart';
import 'package:vocab_ai/models/deck.dart';
import 'package:vocab_ai/models/flashcard.dart';
import 'package:vocab_ai/screens/docks/study/service/spaced_repetition_service.dart';
import 'package:vocab_ai/screens/docks/study/service/text_to_speech_service.dart';
import 'package:vocab_ai/screens/docks/study/widgets/flashcard_widget.dart';
import 'package:vocab_ai/screens/docks/study/widgets/study_components.dart'; // Import file widgets vừa tạo
import 'package:vocab_ai/services/firebase_service.dart';

class StudyScreen extends StatefulWidget {
  final Deck deck;
  const StudyScreen({Key? key, required this.deck}) : super(key: key);

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  // Services
  final FirebaseService _firebaseService = FirebaseService();
  final SpacedRepetitionService _srService = SpacedRepetitionService();
  final TextToSpeechService _tts = TextToSpeechService();

  // State
  List<Flashcard> _cards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = true;

  // Stats
  int _correct = 0;
  int _incorrect = 0;
  int _skipped = 0;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _loadCards();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initializeTTS() async {
    await _tts.initialize();
  }

  Future<void> _loadCards() async {
    try {
      final allCards = await _firebaseService.getFlashcardsByDeck(widget.deck.id);
      final dueCards = _srService.getDueCards(allCards);

      setState(() {
        _cards = dueCards.isEmpty ? allCards : dueCards;
        _isLoading = false;
      });
      await _firebaseService.updateStudyStreak();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _speakCurrentCard() {
    if (_currentIndex < _cards.length) {
      // Thay đổi .term thành thuộc tính chứa từ vựng trong model của bạn
      // Ví dụ: _cards[_currentIndex].frontText
      // _tts.speak(_cards[_currentIndex].term);
      // Tạm thời comment để tránh lỗi nếu model chưa có field
    }
  }

  void _handleAnswer(int quality) async {
    if (_currentIndex >= _cards.length) return;

    final currentCard = _cards[_currentIndex];
    final updatedCard = _srService.updateCard(currentCard, quality);

    try {
      await _firebaseService.updateFlashcard(updatedCard);
      if (mounted) {
        setState(() {
          quality >= 3 ? _correct++ : _incorrect++;
          _cards[_currentIndex] = updatedCard;
          _showAnswer = false;
          _currentIndex++;
        });
        if (_currentIndex >= _cards.length) _showCompletionDialog();
      }
    } catch (e) {
      // Handle error
    }
  }

  void _handleSkip() {
    setState(() {
      _skipped++;
      if (_currentIndex < _cards.length - 1) {
        _currentIndex++;
        _showAnswer = false;
      } else {
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    // Logic dialog giữ nguyên hoặc tách ra file riêng nếu muốn
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Session Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Review complete for ${_cards.length} cards.'),
            const SizedBox(height: 20),
            StudySessionStats(
                correct: _correct, incorrect: _incorrect, skipped: _skipped),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_cards.isEmpty) return _buildEmptyState();
    if (_currentIndex >= _cards.length) return const Scaffold(body: SizedBox()); // Wait for dialog

    final currentCard = _cards[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.deck.name, style: const TextStyle(color: Colors.black)),
        actions: [
          // --- ICON LOA Ở GÓC PHẢI TRÊN CÙNG ---
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.purple),
            tooltip: 'Speak',
            onPressed: _speakCurrentCard,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Progress Bar Widget
          StudyProgressBar(
            currentIndex: _currentIndex,
            totalCards: _cards.length,
          ),

          // 2. Flashcard Main Area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FlashcardWidget(
                  card: currentCard,
                  showAnswer: _showAnswer,
                  onTap: () => setState(() => _showAnswer = !_showAnswer),
                ),
              ),
            ),
          ),

          // 3. Stats Widget
          StudySessionStats(
            correct: _correct,
            incorrect: _incorrect,
            skipped: _skipped,
          ),

          // 4. Controls Widget
          StudyControlsArea(
            showAnswer: _showAnswer,
            onSkip: _handleSkip,
            onShowAnswer: () => setState(() => _showAnswer = true),
            onRate: _handleAnswer,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deck.name)),
      body: const Center(child: Text("All caught up!")),
    );
  }
}