import 'dart:io';
import 'package:vocab_ai/models/vocab_model.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final File? image;
  final VocabResult? vocabResult;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.image,
    this.vocabResult,
  });
}