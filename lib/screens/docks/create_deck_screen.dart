import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../services/firebase_service.dart';

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

  // Controllers for quick add form
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _definitionController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDeckNameDialog();
    });
  }

  void _showDeckNameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Create New Deck'),
        content: TextField(
          controller: _deckNameController,
          decoration: InputDecoration(
            hintText: 'Enter deck name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_deckNameController.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() {
                  _showCardTypeSelection = true;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _selectCardType(String type) {
    setState(() {
      _selectedCardType = type;
      _showCardTypeSelection = false;
      _showAddCards = true;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _addCardToList() {
    if (_wordController.text.isEmpty || _definitionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter word and definition'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _cards.add({
        'word': _wordController.text,
        'definition': _definitionController.text,
        'example': _exampleController.text,
        'imageFile': _selectedImage,
      });

      // Clear form
      _wordController.clear();
      _definitionController.clear();
      _exampleController.clear();
      _selectedImage = null;
    });
  }

  void _removeCard(int index) {
    setState(() {
      _cards.removeAt(index);
    });
  }

  Future<void> _saveDeck() async {
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one card'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

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
          imageUrl = await _firebaseService.uploadImage(
            cardData['imageFile'],
            deck.id,
          );
        }

        final flashcard = Flashcard(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              _cards.indexOf(cardData).toString(),
          word: cardData['word'],
          definition: cardData['definition'],
          example: cardData['example'].toString().isEmpty
              ? null
              : cardData['example'],
          imageUrl: imageUrl,
        );

        await _firebaseService.createFlashcard(flashcard, deck.id);
      }

      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Go back

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showCardTypeSelection) {
      return _buildCardTypeSelectionScreen();
    }

    if (_showAddCards) {
      return _buildAddCardsScreen();
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCardTypeSelectionScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _showCardTypeSelection = false;
            });
            _showDeckNameDialog();
          },
        ),
        title: Text(
          _deckNameController.text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select Card Type',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose how you want to study',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              _buildCardTypeCard(
                'Flashcard',
                'Traditional flip cards with word and definition',
                Icons.style,
                'flashcard',
              ),
              const SizedBox(height: 16),
              _buildCardTypeCard(
                'Multiple Choice',
                'Test yourself with multiple choice questions',
                Icons.quiz,
                'multiple_choice',
              ),
              const SizedBox(height: 16),
              _buildCardTypeCard(
                'Fill in Blank',
                'Complete sentences with the correct word',
                Icons.edit_note,
                'fill_blank',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardTypeCard(
      String title, String description, IconData icon, String type) {
    final isSelected = _selectedCardType == type;
    return GestureDetector(
      onTap: () => _selectCardType(type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.purple : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.purple,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardsScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _deckNameController.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _selectedCardType == 'flashcard'
                  ? 'Flashcard Mode'
                  : _selectedCardType == 'multiple_choice'
                  ? 'Multiple Choice Mode'
                  : 'Fill in Blank Mode',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Add Card Form
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Word',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _wordController,
                  decoration: InputDecoration(
                    labelText: 'Word',
                    hintText: 'e.g., Eloquent',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.text_fields),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _definitionController,
                  decoration: InputDecoration(
                    labelText: 'Definition',
                    hintText: 'e.g., Speaking fluently',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _exampleController,
                  decoration: InputDecoration(
                    labelText: 'Example (Optional)',
                    hintText: 'e.g., Her speech was eloquent',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.format_quote),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: Text(_selectedImage == null
                            ? 'Add Image'
                            : 'Change Image'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addCardToList,
                    icon: const Icon(Icons.add),
                    label: const Text('Add to List'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cards List Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Words Added (${_cards.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_cards.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _cards.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ),

          // Cards Table
          Expanded(
            child: _cards.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No words added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first word above',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      Colors.purple.shade50,
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'No.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Word',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Definition',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Example',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Image',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: _cards.asMap().entries.map((entry) {
                      final index = entry.key;
                      final card = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(
                            ConstrainedBox(
                              constraints:
                              const BoxConstraints(maxWidth: 120),
                              child: Text(
                                card['word'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints:
                              const BoxConstraints(maxWidth: 200),
                              child: Text(
                                card['definition'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints:
                              const BoxConstraints(maxWidth: 150),
                              child: Text(
                                card['example'].isEmpty
                                    ? '-'
                                    : card['example'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                  color: card['example'].isEmpty
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            card['imageFile'] != null
                                ? Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius:
                                BorderRadius.circular(6),
                                image: DecorationImage(
                                  image: FileImage(
                                      card['imageFile']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                                : const Icon(Icons.image_not_supported,
                                color: Colors.grey, size: 20),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 20),
                              onPressed: () => _removeCard(index),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Create Deck (${_cards.length} cards)',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _deckNameController.dispose();
    _wordController.dispose();
    _definitionController.dispose();
    _exampleController.dispose();
    super.dispose();
  }
}