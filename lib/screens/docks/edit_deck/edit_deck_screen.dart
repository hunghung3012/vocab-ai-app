// lib/screens/docks/edit_deck/edit_deck_screen.dart
import 'package:flutter/material.dart';
import 'package:vocab_ai/models/deck.dart';
import 'package:vocab_ai/models/flashcard.dart';
import 'package:vocab_ai/screens/docks/edit_deck/widgets/word_form_dialog.dart';
import 'dart:io';

import 'package:vocab_ai/services/firebase_service.dart';

class EditDeckScreen extends StatefulWidget {
  final Deck deck;

  const EditDeckScreen({Key? key, required this.deck}) : super(key: key);

  @override
  State<EditDeckScreen> createState() => _EditDeckScreenState();
}

class _EditDeckScreenState extends State<EditDeckScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Flashcard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await _firebaseService.getFlashcardsByDeck(widget.deck.id);
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cards: $e')),
        );
      }
    }
  }

  void _showAddWordDialog() {
    showDialog(
      context: context,
      builder: (context) => WordFormDialog(
        onSave: (cardData) async {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (loadingContext) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );

          try {
            String? imageUrl;

            if (cardData['imageFile'] != null) {
              imageUrl = await _firebaseService
                  .uploadImage(cardData['imageFile'], widget.deck.id)
                  .timeout(const Duration(seconds: 12));
            }

            final newCard = Flashcard(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              word: cardData['word'],
              definition: cardData['definition'],
              example: cardData['example'].isEmpty ? null : cardData['example'],
              imageUrl: imageUrl,
            );

            // createFlashcard đã tự động cập nhật deck stats
            await _firebaseService.createFlashcard(newCard, widget.deck.id);
            await _loadCards();

            // Close loading dialog
            if (context.mounted) {
              Navigator.pop(context);
            }

            // Show success message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Word added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            // Close loading dialog
            if (context.mounted) {
              Navigator.pop(context);
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditDialog(Flashcard card) {
    showDialog(
      context: context,
      builder: (context) => WordFormDialog(
        existingCard: card,
        onSave: (cardData) async {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (loadingContext) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );

          try {
            String? imageUrl = cardData['existingImageUrl'];

            // Upload new image if selected
            if (cardData['imageFile'] != null) {
              imageUrl = await _firebaseService
                  .uploadImage(cardData['imageFile'], widget.deck.id)
                  .timeout(const Duration(seconds: 12));
            }

            final updatedCard = card.copyWith(
              word: cardData['word'],
              definition: cardData['definition'],
              example: cardData['example'].isEmpty ? null : cardData['example'],
              imageUrl: imageUrl,
            );

            // updateFlashcard đã tự động cập nhật deck stats
            await _firebaseService.updateFlashcard(updatedCard);
            await _loadCards();

            // Close loading dialog
            if (context.mounted) {
              Navigator.pop(context);
            }

            // Show success message
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Word updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            // Close loading dialog
            if (context.mounted) {
              Navigator.pop(context);
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteCard(Flashcard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Word'),
        content: Text('Are you sure you want to delete "${card.word}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // deleteFlashcard đã tự động cập nhật deck stats
        await _firebaseService.deleteFlashcard(card.id);

        // Reload cards để cập nhật UI
        await _loadCards();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Word deleted successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting card: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.deck.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Words (${_cards.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Cards List
          Expanded(
            child: _cards.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.library_books_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No words in this deck',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first word',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return _buildWordCard(card, index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWordDialog,
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add),
        label: const Text('Add Word'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Done', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildWordCard(Flashcard card, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      card.word,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: InkWell(
                        onTap: () => _showEditDialog(card),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.purple.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteCard(card),
                      tooltip: 'Delete word',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                if (card.imageUrl != null && card.imageUrl!.isNotEmpty)
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.network(
                      card.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),

                // Content section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Definition
                      _buildInfoRow(
                        icon: Icons.description_outlined,
                        label: 'Definition',
                        content: card.definition,
                        color: Colors.blue,
                      ),

                      // Example
                      if (card.example != null && card.example!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.format_quote,
                          label: 'Example',
                          content: card.example!,
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
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

  @override
  void dispose() {
    super.dispose();
  }
}