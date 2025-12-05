import 'package:flutter/material.dart';
import '../../../models/deck.dart';

class QuizDeckCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;
  final bool isSelected;

  const QuizDeckCard({
    Key? key,
    required this.deck,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: isSelected ? Colors.purple.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.purple : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Checkbox indicator
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.purple : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.purple : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isSelected
                      ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.purple.shade100
                        : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.style,
                    color: isSelected ? Colors.purple.shade700 : Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.purple.shade900 : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${deck.totalWords} words • ${deck.progress.toInt()}% mastered',
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.purple.shade700 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: Colors.purple,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}