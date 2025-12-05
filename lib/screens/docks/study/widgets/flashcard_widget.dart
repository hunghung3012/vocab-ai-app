// lib/widgets/flashcard_widget.dart
import 'package:flutter/material.dart';
import 'package:vocab_ai/models/flashcard.dart';
import 'speaker_button.dart';

class FlashcardWidget extends StatelessWidget {
  final Flashcard card;
  final bool showAnswer;
  final VoidCallback onTap;

  const FlashcardWidget({
    Key? key,
    required this.card,
    required this.showAnswer,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 240,
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // SỬ DỤNG STACK ĐỂ ĐÈ ICON LÊN GÓC
        child: Stack(
          children: [
            // 1. Nội dung chính (căn giữa hoặc scroll)
            Center(
              child: showAnswer
                  ? _buildAnswerSide(context)
                  : _buildQuestionSide(context),
            ),

            // 2. Icon loa ghim góc phải trên cùng
            Positioned(
              top: 0,
              right: 0,
              child: SpeakerButton(
                text: card.word, // Luôn đọc từ chính
                size: 48,
                color: Colors.grey[400], // Màu nhạt khi chưa bấm
                activeColor: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSide(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'WORD',
          style: TextStyle(
            fontSize: 14,
            color: Colors.purple,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        // Đã xóa Row và SpeakerButton ở đây, chỉ giữ lại Text
        Text(
          card.word,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Text(
          'Tap to reveal definition',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerSide(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Word (Đã xóa SpeakerButton ở đây)
          Text(
            card.word,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Definition
          Text(
            card.definition,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Example
          if (card.example != null && card.example!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '"${card.example}"',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),

                  SpeakerButton(
                    text: card.example!,
                    size: 32,
                    color: Colors.grey[500],
                    activeColor: Colors.purple,
                  ),
                ],
              ),
            ),
          ],

          // Image
          if (card.imageUrl != null && card.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                card.imageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ],
      ),
    );
  }
}