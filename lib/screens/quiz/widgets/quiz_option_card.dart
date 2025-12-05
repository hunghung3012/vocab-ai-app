import 'package:flutter/material.dart';

class QuizOptionCard extends StatelessWidget {
  final String text;
  final int index; // 0, 1, 2, 3 tương ứng A, B, C, D
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final VoidCallback onTap;

  const QuizOptionCard({
    Key? key,
    required this.text,
    required this.index,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color? borderColor;
    IconData? icon;

    // Logic xác định màu sắc
    if (isAnswered) {
      if (isCorrect) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        icon = Icons.check_circle;
      } else if (isSelected) {
        // Nếu đã trả lời và đây là đáp án sai người dùng chọn
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        icon = Icons.cancel;
      }
    } else if (isSelected) {
      // Đang chọn nhưng chưa confirm (nếu có logic confirm), ở đây tạm thời giống màu tím
      bgColor = Colors.purple.shade50;
      borderColor = Colors.purple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isAnswered ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor ?? Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: borderColor?.withOpacity(0.1) ?? Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: borderColor ?? Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (icon != null) Icon(icon, color: borderColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}