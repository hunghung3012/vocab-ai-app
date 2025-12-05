import 'package:flutter/material.dart';
import 'package:vocab_ai/models/deck.dart';
import 'package:vocab_ai/models/flashcard.dart';
import 'package:vocab_ai/services/firebase_service.dart';

// Import các widgets con
import 'widgets/card_type_selector.dart';
import 'widgets/add_card_form.dart';
import 'widgets/card_list_table.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({Key? key}) : super(key: key);

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _deckNameController = TextEditingController();

  bool _showCardTypeSelection = false;
  bool _showAddCards = false;
  String _selectedCardType = 'flashcard';
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDeckNameDialog());
  }

  // ... (Giữ nguyên logic Dialog Deck Name) ...
  void _showDeckNameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Create New Deck'),
        content: TextField(
          controller: _deckNameController,
          decoration: const InputDecoration(hintText: 'Enter deck name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to previous screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_deckNameController.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() => _showCardTypeSelection = true);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Logic lưu Deck lên Firebase (Giữ nguyên)
  Future<void> _saveDeck() async {
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one card'), backgroundColor: Colors.red));
      return;
    }

    try {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()));

      final deck = Deck(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _deckNameController.text,
        totalWords: _cards.length,
        createdDate: DateTime.now(),
        lastStudiedDate: DateTime.now(),
        flashcardIds: [],
      );

      await _firebaseService.createDeck(deck);

      for (var cardData in _cards) {
        String? imageUrl;
        if (cardData['imageFile'] != null) {
          imageUrl = await _firebaseService.uploadImage(cardData['imageFile'], deck.id);
        }
        final flashcard = Flashcard(
          id: DateTime.now().millisecondsSinceEpoch.toString() + _cards.indexOf(cardData).toString(),
          word: cardData['word'],
          definition: cardData['definition'],
          example: cardData['example'].toString().isEmpty ? null : cardData['example'],
          imageUrl: imageUrl,
        );
        await _firebaseService.createFlashcard(flashcard, deck.id);
      }

      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Back to home
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deck created successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Màn hình chọn Type
    if (_showCardTypeSelection) {
      return CardTypeSelector(
        deckName: _deckNameController.text,
        selectedType: _selectedCardType,
        onTypeSelected: (type) {
          setState(() {
            _selectedCardType = type;
            _showCardTypeSelection = false;
            _showAddCards = true;
          });
        },
        onBack: () {
          setState(() => _showCardTypeSelection = false);
          _showDeckNameDialog();
        },
      );
    }

    // 2. Màn hình thêm Cards (Main Screen)
    if (_showAddCards) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.purple,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_deckNameController.text,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Mode: $_selectedCardType',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        body: SingleChildScrollView(
          // Logic fix overflow nằm ở đây: cuộn cả Form và List cùng nhau
          child: Column(
            children: [
              // Widget Form nhập liệu
              AddCardForm(
                onCardAdded: (newCard) {
                  setState(() => _cards.add(newCard));
                },
              ),

              // Widget Danh sách Cards
              CardListTable(
                cards: _cards,
                onRemove: (index) => setState(() => _cards.removeAt(index)),
                onClearAll: () => setState(() => _cards.clear()),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
          ]),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveDeck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Create Deck (${_cards.length} cards)', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  @override
  void dispose() {
    _deckNameController.dispose();
    super.dispose();
  }
}