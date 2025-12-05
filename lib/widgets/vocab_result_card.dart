import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vocab_ai/models/vocab_model.dart';
import 'package:vocab_ai/models/flashcard.dart';
import 'package:vocab_ai/screens/docks/widgets/deck_selector_sheet.dart';
import 'package:vocab_ai/services/firebase_service.dart';


class VocabResultCard extends StatelessWidget {
  final VocabResult result;
  final File? image;
  final VoidCallback onAddToVocab;

  const VocabResultCard({
    super.key,
    required this.result,
    this.image,
    required this.onAddToVocab,
  });

  Future<void> _showDeckSelector(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DeckSelectorSheet(
        onDeckSelected: (deck) async {
          // Get the root context before any async operations
          final rootContext = Navigator.of(context, rootNavigator: true).context;

          // Show loading
          showDialog(
            context: rootContext,
            barrierDismissible: false,
            builder: (dialogContext) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          try {
            final FirebaseService firebaseService = FirebaseService();

            // Upload image if exists
            String? imageUrl;
            if (image != null) {
              imageUrl = await firebaseService.uploadImage(image!, deck.id);
            }

            // Create flashcard
            final flashcard = Flashcard(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              word: result.word,
              definition: result.definition,
              example: result.exampleEn,
              imageUrl: imageUrl,
            );

            await firebaseService.createFlashcard(flashcard, deck.id);

            // Close loading dialog
            if (rootContext.mounted) {
              Navigator.of(rootContext, rootNavigator: true).pop();
            }

            // Show success message
            if (rootContext.mounted) {
              ScaffoldMessenger.of(rootContext).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text("✅ '${result.word}' added to '${deck.name}'!"),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            // Close loading dialog
            if (rootContext.mounted) {
              Navigator.of(rootContext, rootNavigator: true).pop();
            }

            // Show error message
            if (rootContext.mounted) {
              ScaffoldMessenger.of(rootContext).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6F47EB), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.book, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Vocabulary Card',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Image (if exists)
          if (image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                child: Image.file(image!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Word
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6F47EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.text_fields,
                  size: 18,
                  color: Color(0xFF6F47EB),
                ),
                const SizedBox(width: 8),
                Text(
                  result.word,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6F47EB),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pronunciation
          if (result.pronunciation != null && result.pronunciation!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.record_voice_over,
              label: 'Pronunciation',
              content: result.pronunciation!,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
          ],

          // Part of Speech
          if (result.partOfSpeech != null && result.partOfSpeech!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.category,
              label: 'Part of Speech',
              content: result.partOfSpeech!,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
          ],

          // Definition
          _buildInfoRow(
            icon: Icons.description,
            label: 'Definition',
            content: result.definition,
            color: Colors.green,
          ),

          const SizedBox(height: 12),

          // Example
          if (result.exampleEn != null && result.exampleEn!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.format_quote,
              label: 'Example',
              content: result.exampleEn!,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
          ],

          // Synonyms
          if (result.synonyms != null && result.synonyms!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.link, size: 16, color: Colors.pink.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Synonyms',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: result.synonyms!
                            .map((syn) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.pink.shade200,
                            ),
                          ),
                          child: Text(
                            syn,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.pink.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Add to Deck Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showDeckSelector(context),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                'Add to Deck',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F47EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: const Color(0xFF6F47EB).withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String content,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}