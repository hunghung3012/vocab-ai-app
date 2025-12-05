import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocab_ai/screens/docks/create_deck/service/vocab_enhancement_service.dart';
import 'package:vocab_ai/services/user_preferences.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
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
  final quill.QuillController _exampleController = quill.QuillController.basic();
  final VocabEnhancementService _enhancementService = VocabEnhancementService();

  File? _selectedImage;
  List<String> _synonyms = [];
  bool _isGenerating = false;

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
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);
    FocusScope.of(context).unfocus();

    try {
      final String storedInterests = await UserPreferences.getInterests();

      String contextPrompt;
      if (storedInterests.trim().isNotEmpty) {
        contextPrompt = "User interests: $storedInterests. Create relevant examples.";
      } else {
        contextPrompt = "No interests specified. Use general daily-life examples.";
      }

      final result = await _enhancementService.generateExampleAndSynonyms(
        word: _wordController.text,
        definition: _definitionController.text,
        userInterest: contextPrompt,
      );

      if (result != null) {
        if (mounted) {
          setState(() {
            _exampleController.document = quill.Document()..insert(0, result['example'] ?? '');
            _synonyms = List<String>.from(result['synonyms'] ?? []);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ AI generated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('No result from AI');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _handleAdd() {
    if (_wordController.text.isEmpty || _definitionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter word and definition'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final exampleText = _exampleController.document.toPlainText().trim();

    widget.onCardAdded({
      'word': _wordController.text,
      'definition': _definitionController.text,
      'example': exampleText,
      'synonyms': _synonyms,
      'imageFile': _selectedImage,
    });

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

          // Ô nhập từ vựng
          TextField(
            controller: _wordController,
            decoration: InputDecoration(
              labelText: 'Word',
              hintText: 'e.g., Eloquent',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.text_fields),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          // Ô nhập định nghĩa
          TextField(
            controller: _definitionController,
            decoration: InputDecoration(
              labelText: 'Definition',
              hintText: 'e.g., Speaking fluently',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          // Rich Text Editor với Quill
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Example (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (_isGenerating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton.icon(
                      onPressed: _generateWithAI,
                      icon: Icon(
                        Icons.auto_awesome,
                        color: Colors.purple.shade400,
                        size: 18,
                      ),
                      label: Text(
                        'Generate with AI',
                        style: TextStyle(
                          color: Colors.purple.shade400,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Toolbar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: quill.QuillToolbar.simple(
                  configurations: quill.QuillSimpleToolbarConfigurations(
                    controller: _exampleController,
                    sharedConfigurations: const quill.QuillSharedConfigurations(),
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: false,
                    showInlineCode: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showClearFormat: true,
                    showAlignmentButtons: false,
                    showLeftAlignment: false,
                    showCenterAlignment: false,
                    showRightAlignment: false,
                    showJustifyAlignment: false,
                    showHeaderStyle: false,
                    showListNumbers: false,
                    showListBullets: false,
                    showListCheck: false,
                    showCodeBlock: false,
                    showQuote: false,
                    showIndent: false,
                    showLink: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showSmallButton: false,
                    showDirection: false,
                    multiRowsDisplay: false,
                    toolbarIconAlignment: WrapAlignment.start,
                    toolbarIconCrossAlignment: WrapCrossAlignment.center,
                  ),
                ),
              ),

              // Editor
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: quill.QuillEditor.basic(
                  configurations: quill.QuillEditorConfigurations(
                    controller: _exampleController,
                    readOnly: false,
                    placeholder: 'Type your example here... Use toolbar above to format text.',
                    padding: const EdgeInsets.all(12),
                    sharedConfigurations: const quill.QuillSharedConfigurations(),
                  ),
                ),
              ),
            ],
          ),

          // Hiển thị danh sách từ đồng nghĩa
          if (_synonyms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
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

          // Nút chọn ảnh
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(_selectedImage == null ? 'Add Image' : 'Change Image'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => setState(() => _selectedImage = null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Nút Add to List
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleAdd,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'Add to List',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
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