import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:io';

import 'package:vocab_ai/models/flashcard.dart';
import 'package:vocab_ai/screens/docks/create_deck/service/vocab_enhancement_service.dart';
import 'package:vocab_ai/services/user_preferences.dart';


class WordFormDialog extends StatefulWidget {
  final Flashcard? existingCard; // null = Add mode, not null = Edit mode
  final Function(Map<String, dynamic>) onSave;

  const WordFormDialog({
    Key? key,
    this.existingCard,
    required this.onSave,
  }) : super(key: key);

  @override
  State<WordFormDialog> createState() => _WordFormDialogState();
}

class _WordFormDialogState extends State<WordFormDialog> {
  late TextEditingController _wordController;
  late TextEditingController _definitionController;
  late quill.QuillController _exampleController;
  final VocabEnhancementService _enhancementService = VocabEnhancementService();

  File? _selectedImage;
  String? _existingImageUrl;
  List<String> _synonyms = [];
  bool _isGenerating = false;
  bool get isEditMode => widget.existingCard != null;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    if (isEditMode) {
      _wordController = TextEditingController(text: widget.existingCard!.word);
      _definitionController = TextEditingController(text: widget.existingCard!.definition);
      _exampleController = quill.QuillController.basic();

      // Set existing example text
      if (widget.existingCard!.example != null && widget.existingCard!.example!.isNotEmpty) {
        _exampleController.document = quill.Document()..insert(0, widget.existingCard!.example!);
      }

      _existingImageUrl = widget.existingCard!.imageUrl;
    } else {
      _wordController = TextEditingController();
      _definitionController = TextEditingController();
      _exampleController = quill.QuillController.basic();
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _existingImageUrl = null; // Clear existing URL if new image picked
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

  void _handleSave() {
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

    widget.onSave({
      'word': _wordController.text,
      'definition': _definitionController.text,
      'example': exampleText,
      'synonyms': _synonyms,
      'imageFile': _selectedImage,
      'existingImageUrl': _existingImageUrl,
    });

    Navigator.pop(context);
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
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditMode ? Icons.edit : Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditMode ? 'Edit Word' : 'Add New Word',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Word Field
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

                    // Definition Field
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

                    // Example Field with Rich Text Editor
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
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          ),
                          child: quill.QuillEditor.basic(
                            configurations: quill.QuillEditorConfigurations(
                              controller: _exampleController,
                              readOnly: false,
                              placeholder: 'Type your example here...',
                              padding: const EdgeInsets.all(12),
                              sharedConfigurations: const quill.QuillSharedConfigurations(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Synonyms Display
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

                    // Image Picker
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: Text(
                              (_selectedImage != null || _existingImageUrl != null)
                                  ? 'Change Image'
                                  : 'Add Image',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (_selectedImage != null || _existingImageUrl != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _selectedImage != null
                                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                  : Image.network(_existingImageUrl!, fit: BoxFit.cover),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                            onPressed: () => setState(() {
                              _selectedImage = null;
                              _existingImageUrl = null;
                            }),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEditMode ? 'Save Changes' : 'Add Word',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}