import 'package:flutter/material.dart';
import '../../models/deck.dart';
import 'multiple_choice_quiz_screen.dart';
import 'widgets/quiz_type_card.dart';

class QuizTypeSelectionScreen extends StatelessWidget {
  final Deck deck;

  const QuizTypeSelectionScreen({Key? key, required this.deck})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          deck.name,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Quiz Type',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a quiz format to test your knowledge',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              QuizTypeCard(
                title: 'Multiple Choice',
                description: 'Select the correct meaning of each word',
                wordCount: '${deck.totalWords} words',
                difficulty: 'Intermediate',
                difficultyColor: Colors.orange,
                icon: Icons.check_circle_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MultipleChoiceQuizScreen(deck: deck),
                    ),
                  );
                },
              ),
              QuizTypeCard(
                title: 'Fill in the Blank',
                description: 'Complete sentences with the right vocabulary',
                wordCount: '15 words',
                difficulty: 'Advanced',
                difficultyColor: Colors.red,
                icon: Icons.edit_outlined,
                onTap: () => _showComingSoon(context),
              ),
              QuizTypeCard(
                title: 'Matching',
                description: 'Match words with their definitions',
                wordCount: '25 words',
                difficulty: 'Beginner',
                difficultyColor: Colors.green,
                icon: Icons.compare_arrows,
                onTap: () => _showComingSoon(context),
              ),
              QuizTypeCard(
                title: 'Listen & Spell',
                description: 'Hear the word and spell it correctly',
                wordCount: '18 words',
                difficulty: 'Intermediate',
                difficultyColor: Colors.orange,
                icon: Icons.hearing,
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon!')),
    );
  }
}