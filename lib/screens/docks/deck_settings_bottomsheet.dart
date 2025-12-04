import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../../models/deck.dart';
import '../../services/firebase_service.dart';

void showDeckSettings(BuildContext context, Deck deck) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DeckSettingsBottomSheet(deck: deck),
  );
}

class DeckSettingsBottomSheet extends StatelessWidget {
  final Deck deck;
  final FirebaseService _firebaseService = FirebaseService();

  DeckSettingsBottomSheet({Key? key, required this.deck}) : super(key: key);

  Future<void> _exportDeck(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Exporting deck...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Load flashcards
      final cards = await _firebaseService.getFlashcardsByDeck(deck.id);

      if (cards.isEmpty) {
        Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cards to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final dbPath = path.join(tempDir.path, 'collection.anki2');

      // Delete old file if exists
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // Create database with optimized settings
      final db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          // Enable optimizations for faster write
          await db.execute('PRAGMA synchronous = OFF');
          await db.execute('PRAGMA journal_mode = MEMORY');
          await db.execute('PRAGMA temp_store = MEMORY');
          await db.execute('PRAGMA cache_size = 10000');
        },
      );

      // Create schema in single transaction
      await db.transaction((txn) async {
        // Notes table
        await txn.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY,
            guid TEXT NOT NULL,
            mid INTEGER NOT NULL,
            mod INTEGER NOT NULL,
            usn INTEGER NOT NULL,
            tags TEXT NOT NULL,
            flds TEXT NOT NULL,
            sfld TEXT NOT NULL,
            csum INTEGER NOT NULL,
            flags INTEGER NOT NULL,
            data TEXT NOT NULL
          )
        ''');

        // Cards table
        await txn.execute('''
          CREATE TABLE cards (
            id INTEGER PRIMARY KEY,
            nid INTEGER NOT NULL,
            did INTEGER NOT NULL,
            ord INTEGER NOT NULL,
            mod INTEGER NOT NULL,
            usn INTEGER NOT NULL,
            type INTEGER NOT NULL,
            queue INTEGER NOT NULL,
            due INTEGER NOT NULL,
            ivl INTEGER NOT NULL,
            factor INTEGER NOT NULL,
            reps INTEGER NOT NULL,
            lapses INTEGER NOT NULL,
            left INTEGER NOT NULL,
            odue INTEGER NOT NULL,
            odid INTEGER NOT NULL,
            flags INTEGER NOT NULL,
            data TEXT NOT NULL
          )
        ''');

        // Collection table
        await txn.execute('''
          CREATE TABLE col (
            id INTEGER PRIMARY KEY,
            crt INTEGER NOT NULL,
            mod INTEGER NOT NULL,
            scm INTEGER NOT NULL,
            ver INTEGER NOT NULL,
            dty INTEGER NOT NULL,
            usn INTEGER NOT NULL,
            ls INTEGER NOT NULL,
            conf TEXT NOT NULL,
            models TEXT NOT NULL,
            decks TEXT NOT NULL,
            dconf TEXT NOT NULL,
            tags TEXT NOT NULL
          )
        ''');

        // Insert collection metadata
        final now = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('col', {
          'id': 1,
          'crt': now ~/ 1000,
          'mod': now,
          'scm': now,
          'ver': 11,
          'dty': 0,
          'usn': 0,
          'ls': 0,
          'conf': '{"nextPos":1,"estTimes":true,"activeDecks":[1]}',
          'models': '{"1":{"id":1,"name":"Basic","type":0,"mod":$now,"flds":[{"name":"Front","ord":0,"sticky":false},{"name":"Back","ord":1,"sticky":false}],"tmpls":[{"name":"Card 1","ord":0,"qfmt":"{{Front}}","afmt":"{{FrontSide}}<hr id=answer>{{Back}}"}]}}',
          'decks': '{"1":{"id":1,"name":"${_escapeJson(deck.name)}","mod":$now,"conf":1}}',
          'dconf': '{"1":{"id":1,"name":"Default","new":{"perDay":20}}}',
          'tags': '{}'
        });
      });

      // Bulk insert cards using batch (MUCH FASTER)
      await db.transaction((txn) async {
        final batch = txn.batch();
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        for (int i = 0; i < cards.length; i++) {
          final card = cards[i];
          final noteId = i + 1;

          // Prepare fields: Front | Back | Example
          String fields = '${_escapeField(card.word)}\x1f${_escapeField(card.definition)}';
          if (card.example != null && card.example!.isNotEmpty) {
            fields += '\x1f${_escapeField(card.example!)}';
          }

          // Insert note
          batch.insert('notes', {
            'id': noteId,
            'guid': card.id,
            'mid': 1,
            'mod': now,
            'usn': -1,
            'tags': '',
            'flds': fields,
            'sfld': _escapeField(card.word),
            'csum': card.word.hashCode.abs(),
            'flags': 0,
            'data': ''
          });

          // Insert card
          batch.insert('cards', {
            'id': noteId,
            'nid': noteId,
            'did': 1,
            'ord': 0,
            'mod': now,
            'usn': -1,
            'type': 0,
            'queue': 0,
            'due': noteId,
            'ivl': 0,
            'factor': 2500,
            'reps': 0,
            'lapses': 0,
            'left': 0,
            'odue': 0,
            'odid': 0,
            'flags': 0,
            'data': ''
          });
        }

        await batch.commit(noResult: true);
      });

      // Close database
      await db.close();

      // Create ZIP file (APKG)
      final apkgPath = path.join(
        tempDir.path,
        '${deck.name.replaceAll(RegExp(r'[^\w\s-]'), '_')}.apkg',
      );

      // Delete old apkg if exists
      final apkgFile = File(apkgPath);
      if (await apkgFile.exists()) {
        await apkgFile.delete();
      }

      // Create archive
      final encoder = ZipFileEncoder();
      encoder.create(apkgPath);
      encoder.addFile(File(dbPath));
      encoder.close();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Share the file
      await Share.shareXFiles(
        [XFile(apkgPath)],
        subject: '${deck.name} - Anki Deck',
        text: 'Exported from Vocab AI',
      );

      // Cleanup temp files
      try {
        await File(dbPath).delete();
        await File(apkgPath).delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deck "${deck.name}" exported successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading if still open
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper to escape JSON strings
  String _escapeJson(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  // Helper to escape field content
  String _escapeField(String input) {
    return input
        .replaceAll('\x1f', '')  // Remove field separator
        .replaceAll('\n', '<br>')
        .trim();
  }

  Future<void> _deleteDeck(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Deck'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${deck.name}"?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );

        await _firebaseService.deleteDeck(deck.id);

        if (context.mounted) {
          Navigator.pop(context); // Close loading
          Navigator.pop(context); // Close bottom sheet

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deck deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting deck: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Deck Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              deck.name,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Deck Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    Icons.book,
                    '${deck.totalWords}',
                    'Words',
                    Colors.purple,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.purple.shade200,
                  ),
                  _buildInfoItem(
                    Icons.trending_up,
                    '${deck.progress.toInt()}%',
                    'Progress',
                    Colors.blue,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.purple.shade200,
                  ),
                  _buildInfoItem(
                    Icons.check_circle,
                    '${deck.masteredWords}',
                    'Mastered',
                    Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Export Option
            _buildOptionTile(
              icon: Icons.upload_file,
              iconColor: Colors.blue,
              iconBgColor: Colors.blue.shade50,
              title: 'Export to Anki',
              subtitle: 'Export as .apkg file',
              onTap: () {
                Navigator.pop(context);
                _exportDeck(context);
              },
            ),

            const SizedBox(height: 12),

            // Delete Option
            _buildOptionTile(
              icon: Icons.delete_forever,
              iconColor: Colors.red,
              iconBgColor: Colors.red.shade50,
              title: 'Delete Deck',
              subtitle: 'This action cannot be undone',
              titleColor: Colors.red,
              onTap: () => _deleteDeck(context),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}