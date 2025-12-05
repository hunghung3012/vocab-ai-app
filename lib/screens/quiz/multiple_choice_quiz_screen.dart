import 'package:flutter/material.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../services/firebase_service.dart';
import 'widgets/quiz_option_card.dart';

class MultipleChoiceQuizScreen extends StatefulWidget {
  final Deck deck;

  const MultipleChoiceQuizScreen({Key? key, required this.deck})
      : super(key: key);

  @override
  State<MultipleChoiceQuizScreen> createState() =>
      _MultipleChoiceQuizScreenState();
}

class _MultipleChoiceQuizScreenState extends State<MultipleChoiceQuizScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Flashcard> _cards = [];
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool _isLoading = true;
  List<String> _options = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final cards = await _firebaseService.getFlashcardsByDeck(widget.deck.id);

      if (cards.isEmpty) {
        setState(() {
          _errorMessage = 'This deck has no flashcards yet. Add some cards first!';
          _isLoading = false;
        });
        return;
      }

      if (cards.length < 4) {
        setState(() {
          _errorMessage = 'This deck needs at least 4 flashcards to take a quiz.';
          _isLoading = false;
        });
        return;
      }

      cards.shuffle();
      setState(() {
        _cards = cards.take(20).toList();
        _isLoading = false;
      });
      _generateOptions();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading quiz: $e';
        _isLoading = false;
      });
    }
  }

  void _generateOptions() {
    if (_cards.isEmpty || _currentIndex >= _cards.length) return;

    final currentCard = _cards[_currentIndex];
    final correctAnswer = currentCard.definition;

    // Lấy tất cả các cards khác
    final otherCards = _cards.where((c) => c.id != currentCard.id).toList();

    if (otherCards.length < 3) {
      setState(() {
        _errorMessage = 'Not enough cards to generate quiz options';
      });
      return;
    }

    otherCards.shuffle();
    final wrongAnswers = otherCards.take(3).map((c) => c.definition).toList();

    final options = [correctAnswer, ...wrongAnswers];
    options.shuffle();

    setState(() {
      _options = options;
    });
  }

  void _selectAnswer(String answer) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;

      if (answer == _cards[_currentIndex].definition) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
      });
      _generateOptions();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    final percentage = ((_score / _cards.length) * 100).toInt();
    String emoji = '🎉';
    String message = 'Great job!';

    if (percentage >= 90) {
      emoji = '🏆';
      message = 'Outstanding!';
    } else if (percentage >= 70) {
      emoji = '🎉';
      message = 'Great job!';
    } else if (percentage >= 50) {
      emoji = '👍';
      message = 'Good effort!';
    } else {
      emoji = '📚';
      message = 'Keep practicing!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$emoji Quiz Complete!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            const SizedBox(height: 16),
            Text('Your Score', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              '$_score / ${_cards.length}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
            const SizedBox(height: 8),
            Text('$percentage%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to quiz selection
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _selectedAnswer = null;
                _isAnswered = false;
              });
              _cards.shuffle();
              _generateOptions();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Quiz', style: TextStyle(color: Colors.black)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.orange[300]),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentCard = _cards[_currentIndex];
    final progress = (_currentIndex + 1) / _cards.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit Quiz?'),
                content: const Text('Your progress will be lost.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Exit', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          'Question ${_currentIndex + 1}/${_cards.length}',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Score: $_score',
                  style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            minHeight: 6,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'What is the meaning of:',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      currentCard.word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Select the correct answer:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),

                  // Danh sách đáp án sử dụng QuizOptionCard
                  ..._options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    return QuizOptionCard(
                      text: option,
                      index: index,
                      isSelected: _selectedAnswer == option,
                      isAnswered: _isAnswered,
                      isCorrect: option == currentCard.definition,
                      onTap: () => _selectAnswer(option),
                    );
                  }).toList(),

                  // Phần hiển thị kết quả đúng/sai dưới cùng
                  if (_isAnswered)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (_selectedAnswer == currentCard.definition)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Correct! 🎉',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info, color: Colors.orange),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Correct answer:',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          currentCard.definition,
                                          style: TextStyle(
                                            color: Colors.orange.shade900,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _nextQuestion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _currentIndex < _cards.length - 1
                                    ? 'Next Question'
                                    : 'See Results',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}