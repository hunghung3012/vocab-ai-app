import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import '../../../widgets/vocab_result_card.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onAddToVocab;

  const ChatBubble({
    super.key,
    required this.message,
    this.onAddToVocab,
  });

  @override
  Widget build(BuildContext context) {
    // CASE 1: Hiển thị Vocab Card (Kết quả từ điển/AI)
    if (message.vocabResult != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBotAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: VocabResultCard(
                result: message.vocabResult!,
                image: message.image,
                onAddToVocab: onAddToVocab ?? () {},
              ),
            ),
          ],
        ),
      );
    }

    // CASE 2: Hiển thị tin nhắn thông thường (Text/Image)
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildBotAvatar(),
          if (!isUser) const SizedBox(width: 8),

          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Hiển thị ảnh gửi đi (nếu có)
                if (message.image != null && message.vocabResult == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
                        child: Image.file(message.image!, fit: BoxFit.cover),
                      ),
                    ),
                  ),

                // Hiển thị Text
                if (message.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(colors: [Color(0xFF6F47EB), Color(0xFF8B5CF6)])
                          : null,
                      color: isUser ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser ? null : Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: isUser
                              ? const Color(0xFF6F47EB).withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6F47EB).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.smart_toy_outlined, color: Color(0xFF6F47EB), size: 18),
    );
  }
}