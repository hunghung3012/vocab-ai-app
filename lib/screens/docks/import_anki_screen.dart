import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../services/firebase_service.dart';

class ImportAnkiScreen extends StatefulWidget {
  const ImportAnkiScreen({Key? key}) : super(key: key);

  @override
  State<ImportAnkiScreen> createState() => _ImportAnkiScreenState();
}

class _ImportAnkiScreenState extends State<ImportAnkiScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isImporting = false;
  String? _selectedFileName;
  String _importStatus = '';

  void _log(String message) {
    print('[IMPORT] ${DateTime.now().toString().split(' ')[1]}: $message');
  }

  Future<void> _pickAndImportAnkiFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path!;
      final fileName = result.files.first.name;

      if (!fileName.toLowerCase().endsWith('.apkg')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a valid .apkg file."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isImporting = true;
        _selectedFileName = fileName;
        _importStatus = 'Reading file...';
      });

      final file = File(filePath);
      await _importAnkiDeck(file);
    } catch (e) {
      _log('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importStatus = '';
        });
      }
    }
  }

  Future<void> _importAnkiDeck(File apkgFile) async {
    Database? db;
    final tempFiles = <File>[];

    try {
      setState(() => _importStatus = 'Extracting archive...');
      _log('Starting import process');

      // Read and extract .apkg file
      final bytes = await apkgFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      _log('Archive extracted, files: ${archive.length}');

      // Find collection.anki2 database
      final dbFile = archive.firstWhere(
            (file) => file.name == 'collection.anki2',
      );

      // Extract database to temp directory
      final tempDir = Directory.systemTemp;
      final dbPath = path.join(tempDir.path, 'temp_anki_${DateTime.now().millisecondsSinceEpoch}.db');
      final dbFileOutput = File(dbPath);
      await dbFileOutput.writeAsBytes(dbFile.content as List<int>);
      tempFiles.add(dbFileOutput);

      setState(() => _importStatus = 'Reading cards...');

      // Open SQLite database
      db = await openDatabase(dbPath);

      // Query notes - CHECK nếu có column imageUrl
      final notes = await db.query('notes');
      _log('Found ${notes.length} notes');

      if (notes.isEmpty) {
        throw Exception('No cards found in Anki deck');
      }

      // Check if imageUrl column exists
      final columns = await db.rawQuery('PRAGMA table_info(notes)');
      final hasImageUrl = columns.any((col) => col['name'] == 'imageUrl');
      _log('Has imageUrl column: $hasImageUrl');

      setState(() => _importStatus = 'Creating deck...');

      // Create deck
      final deckId = DateTime.now().millisecondsSinceEpoch.toString();
      final deckName = _selectedFileName?.replaceAll('.apkg', '') ?? 'Imported Deck';

      final deck = Deck(
        id: deckId,
        name: deckName,
        flashcardIds: [],
        totalWords: notes.length,
      );

      await _firebaseService.createDeck(deck);
      _log('Deck created: $deckName');

      // Extract and upload media files
      setState(() => _importStatus = 'Processing media files...');

      // Parse media mapping file
      Map<String, String> mediaMapping = {};
      final mediaFile = archive.firstWhere(
            (file) => file.name == 'media',
        orElse: () => ArchiveFile('', 0, null),
      );

      if (mediaFile.content != null) {
        try {
          final mediaJson = String.fromCharCodes(mediaFile.content as List<int>);
          _log('Media mapping file content: $mediaJson');

          // Parse JSON: {"0": "filename.jpg", "1": "another.png"}
          final mediaData = json.decode(mediaJson) as Map<String, dynamic>;
          mediaMapping = mediaData.map((k, v) => MapEntry(k, v.toString()));
          _log('Media mapping parsed: ${mediaMapping.length} entries');
        } catch (e) {
          _log('Error parsing media file: $e');
        }
      }

      // Upload media files to Firebase Storage
      final mediaUrlMap = <String, String>{};

      for (var file in archive) {
        // Skip database and media mapping files
        if (file.name == 'collection.anki2' || file.name == 'media') continue;

        if (file.content != null && file.content!.isNotEmpty) {
          _log('Processing media file: ${file.name}');

          final mediaPath = path.join(tempDir.path, file.name);
          final mediaFileOutput = File(mediaPath);
          await mediaFileOutput.writeAsBytes(file.content as List<int>);
          tempFiles.add(mediaFileOutput);

          // Upload to Firebase Storage
          try {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('flashcard_images')
                .child('$deckId/${timestamp}_${file.name}');

            await storageRef.putFile(mediaFileOutput);
            final downloadUrl = await storageRef.getDownloadURL();

            // Map both: numeric key (from media file) and actual filename
            mediaUrlMap[file.name] = downloadUrl;

            // Also map by the key if it exists in mediaMapping
            final numericKey = mediaMapping.entries
                .firstWhere((entry) => entry.value == file.name,
                orElse: () => const MapEntry('', ''))
                .key;
            if (numericKey.isNotEmpty) {
              mediaUrlMap[numericKey] = downloadUrl;
            }

            _log('Uploaded ${file.name} -> $downloadUrl');
          } catch (e) {
            _log('Error uploading media ${file.name}: $e');
          }
        }
      }

      _log('Total media files uploaded: ${mediaUrlMap.length}');

      // Import flashcards
      setState(() => _importStatus = 'Importing cards...');

      int imported = 0;
      for (var note in notes) {
        final fields = (note['flds'] as String).split('\x1f');

        if (fields.length >= 2) {
          final cardId = '${DateTime.now().millisecondsSinceEpoch}_$imported';

          // ĐỌC imageUrl từ database nếu có
          String? imageUrl;

          if (hasImageUrl && note['imageUrl'] != null && (note['imageUrl'] as String).isNotEmpty) {
            imageUrl = note['imageUrl'] as String;
            _log('Card ${imported + 1}: Found imageUrl from database: $imageUrl');
          } else {
            // Fallback: Extract image từ HTML nếu không có trong database
            final combinedText = fields.join(' ');
            final imgRegex1 = RegExp(r'''<img[^>]+src=['"]([^'"]+)['"]''');

            final imgMatch1 = imgRegex1.firstMatch(combinedText);

            if (imgMatch1 != null) {
              imageUrl = imgMatch1.group(1);
              _log('Card ${imported + 1}: Found imageUrl from HTML: $imageUrl');
            }
          }

          final flashcard = Flashcard(
            id: cardId,
            word: _cleanHtml(fields[0]),
            definition: _cleanHtml(fields[1]),
            example: fields.length > 2 ? _cleanHtml(fields[2]) : null,
            imageUrl: imageUrl,
          );

          await _firebaseService.createFlashcard(flashcard, deckId);
          imported++;

          setState(() => _importStatus = 'Imported $imported/${notes.length} cards...');
        }
      }

      _log('Import completed: $imported cards');

      // Cleanup
      await db.close();
      for (var file in tempFiles) {
        try {
          await file.delete();
        } catch (e) {
          _log('Error deleting temp file: $e');
        }
      }

      if (mounted) {
        final cardsWithImages = notes.where((n) =>
        hasImageUrl && n['imageUrl'] != null && (n['imageUrl'] as String).isNotEmpty
        ).length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Successfully imported $imported cards${cardsWithImages > 0 ? ' ($cardsWithImages with images)' : ''}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _log('Import failed: $e');

      if (db != null) {
        await db.close();
      }

      // Cleanup temp files
      for (var file in tempFiles) {
        try {
          await file.delete();
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing Anki deck: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _cleanHtml(String html) {
    // Don't remove img tags entirely - we need them to detect images
    return html
        .replaceAll(RegExp(r'<img[^>]*>'), '') // Remove img tags from display text
        .replaceAll(RegExp(r'\[sound:[^\]]+\]'), '') // Remove sound tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'VocabAI',
          style: TextStyle(
            color: Colors.purple,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import Anki Deck',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your Anki deck (.apkg file) to import',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Import Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.purple,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.upload_file,
                        size: 64,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Drop your Anki file here',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'or',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isImporting ? null : _pickAndImportAnkiFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isImporting
                          ? Column(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          if (_importStatus.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _importStatus,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      )
                          : const Text(
                        'Browse Files',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_selectedFileName != null && !_isImporting) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.file_present,
                              color: Colors.purple,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _selectedFileName!,
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'How to export from Anki',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep('1', 'Open Anki desktop application'),
                    _buildInstructionStep('2', 'Select your deck'),
                    _buildInstructionStep('3', 'Click File → Export'),
                    _buildInstructionStep('4', 'Choose "Anki Deck Package (*.apkg)"'),
                    _buildInstructionStep('5', 'Check "Include media" for images'),
                    _buildInstructionStep('6', 'Save and upload here'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Supported formats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Supported Format',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '.apkg',
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Anki Deck Package with media',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}