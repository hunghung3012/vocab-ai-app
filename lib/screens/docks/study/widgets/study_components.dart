import 'package:flutter/material.dart';

// 1. Widget hiển thị thanh tiến trình
class StudyProgressBar extends StatelessWidget {
  final int currentIndex;
  final int totalCards;

  const StudyProgressBar({
    Key? key,
    required this.currentIndex,
    required this.totalCards,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = totalCards > 0 ? (currentIndex + 1) / totalCards : 0.0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${currentIndex + 1} of $totalCards',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

// 2. Widget hiển thị thống kê phiên học (Correct/Incorrect/Skipped)
class StudySessionStats extends StatelessWidget {
  final int correct;
  final int incorrect;
  final int skipped;

  const StudySessionStats({
    Key? key,
    required this.correct,
    required this.incorrect,
    required this.skipped,
  }) : super(key: key);

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Correct', correct, Colors.green),
          _buildStatItem('Incorrect', incorrect, Colors.red),
          _buildStatItem('Skipped', skipped, Colors.orange),
        ],
      ),
    );
  }
}

// 3. Widget chứa các nút điều khiển (Skip, Show Answer, Rating)
class StudyControlsArea extends StatelessWidget {
  final bool showAnswer;
  final VoidCallback onSkip;
  final VoidCallback onShowAnswer;
  final Function(int) onRate;

  const StudyControlsArea({
    Key? key,
    required this.showAnswer,
    required this.onSkip,
    required this.onShowAnswer,
    required this.onRate,
  }) : super(key: key);

  Widget _buildRatingButton(String label, Color color, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showAnswer) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            _buildRatingButton('Again', Colors.red, () => onRate(0)),
            const SizedBox(width: 8),
            _buildRatingButton('Hard', Colors.orange, () => onRate(2)),
            const SizedBox(width: 8),
            _buildRatingButton('Good', Colors.blue, () => onRate(3)),
            const SizedBox(width: 8),
            _buildRatingButton('Easy', Colors.green, () => onRate(5)),
          ],
        ),
      );
    } else {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onShowAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Show Answer', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    }
  }
}