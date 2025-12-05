import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocab_ai/screens/docks/create_deck/service/vocab_enhancement_service.dart';
import 'dart:io';


class AddCardForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onCardAdded;

  const AddCardForm({Key? key, required this.onCardAdded}) : super(key: key);

  @override
  State<AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends State<AddCardForm> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _definitionController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  final VocabEnhancementService _enhancementService = VocabEnhancementService();

  File? _selectedImage;
  List<String> _synonyms = [];
  bool _isGenerating = false;

  // 🎯 Sở thích cá nhân - Bạn có thể chỉnh chi tiết ở đây
  static const String userPersonalInterest = """
I'm a passionate football fan who loves watching Premier League matches, 
especially Chelsea FC. I also enjoy playing FIFA video games with friends, 
discussing tactics and formations. In my free time, I read books about 
sports psychology and leadership in football. I dream of becoming a sports 
analyst or commentator someday.
""";

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _generateWithAI() async {
    if (_wordController.text.isEmpty || _definitionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter word and definition first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final result = await _enhancementService.generateExampleAndSynonyms(
        word: _wordController.text,
        definition: _definitionController.text,
        userInterest: userPersonalInterest,
      );

      if (result != null) {
        setState(() {
          _exampleController.text = result['example'] ?? '';
          _synonyms = List<String>.from(result['synonyms'] ?? []);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ AI generated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('No result from AI');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _handleAdd() {
    if (_wordController.text.isEmpty || _definitionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter word and definition'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Gửi dữ liệu ra bên ngoài
    widget.onCardAdded({
      'word': _wordController.text,
      'definition': _definitionController.text,
      'example': _exampleController.text,
      'synonyms': _synonyms,
      'imageFile': _selectedImage,
    });

    // Reset form
    _wordController.clear();
    _definitionController.clear();
    _exampleController.clear();
    setState(() {
      _selectedImage = null;
      _synonyms = [];
    });
  }

  @override
  void dispose() {
    _wordController.dispose();
    _definitionController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Word',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _wordController,
            decoration: InputDecoration(
              labelText: 'Word',
              hintText: 'e.g., Eloquent',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.text_fields),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _definitionController,
            decoration: InputDecoration(
              labelText: 'Definition',
              hintText: 'e.g., Speaking fluently',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          // Example field với AI button
          TextField(
            controller: _exampleController,
            decoration: InputDecoration(
              labelText: 'Example (Optional)',
              hintText: 'e.g., Her speech was eloquent',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.format_quote),
              suffixIcon: _isGenerating
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : IconButton(
                icon: Icon(
                  Icons.auto_awesome,
                  color: Colors.purple.shade400,
                ),
                tooltip: 'Generate with AI',
                onPressed: _isGenerating ? null : _generateWithAI,
              ),
            ),
            maxLines: 2,
          ),

          // Hiển thị synonyms nếu có
          if (_synonyms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link, size: 16, color: Colors.purple.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Related Words:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _synonyms.map((synonym) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Text(
                        synonym,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(_selectedImage == null ? 'Add Image' : 'Change Image'),
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
                  onPressed: () => setState(() => _selectedImage = null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add to List'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}