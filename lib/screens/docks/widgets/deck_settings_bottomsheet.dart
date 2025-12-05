import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../../../models/deck.dart';
import '../../../services/firebase_service.dart';

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

  void _log(String message) {
    print('[EXPORT] ${DateTime.now().toString().split(' ')[1]}: $message');
  }

  Future<void> _exportDeck(BuildContext context) async {
    final totalStart = DateTime.now();
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    BuildContext? dialogContext;

    try {
      // Show loading dialog
      showDialog(
        context: rootContext,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Exporting deck...", textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      );

      // Load cards
      final cards = await _firebaseService.getFlashcardsByDeck(deck.id);
      if (cards.isEmpty) {
        if (dialogContext != null) Navigator.of(dialogContext!, rootNavigator: true).pop();
        ScaffoldMessenger.of(rootContext).showSnackBar(
          const SnackBar(content: Text("No cards to export")),
        );
        return;
      }

      // Create APKG file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dbPath = path.join(tempDir.path, "col_$timestamp.anki2");

      final apkgPath = await _createApkgFile(
        cards: cards,
        deckName: deck.name,
        dbPath: dbPath,
        tempDir: tempDir,
        timestamp: timestamp,
      );

      // Close loading dialog
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }

      // Share file
      await Share.shareXFiles(
        [XFile(apkgPath)],
        subject: "${deck.name} - Anki Deck",
        text: "${cards.length} flashcards exported!",
      );

      // Cleanup
      try {
        await File(dbPath).delete();
        await Future.delayed(const Duration(seconds: 1));
        await File(apkgPath).delete();
      } catch (_) {}

      final total = DateTime.now().difference(totalStart).inSeconds;
      ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text("✅ Exported ${cards.length} cards in ${total}s"))
      );

    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(content: Text("Export failed: $e")),
      );
    }
  }

  Future<void> _exportToDevice(BuildContext context) async {
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    BuildContext? dialogContext;

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        PermissionStatus status;

        if (await _isAndroid13OrHigher()) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.storage.request();

          if (status.isDenied) {
            ScaffoldMessenger.of(rootContext).showSnackBar(
              const SnackBar(
                content: Text("Storage permission is required to save files"),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          if (status.isPermanentlyDenied) {
            ScaffoldMessenger.of(rootContext).showSnackBar(
              SnackBar(
                content: const Text("Please enable storage permission in Settings"),
                action: SnackBarAction(
                  label: "Settings",
                  onPressed: () => openAppSettings(),
                ),
                duration: const Duration(seconds: 5),
              ),
            );
            return;
          }
        }
      }

      // Show loading dialog
      showDialog(
        context: rootContext,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Exporting to device..."),
                ],
              ),
            ),
          );
        },
      );

      // Load cards
      final cards = await _firebaseService.getFlashcardsByDeck(deck.id);
      if (cards.isEmpty) {
        if (dialogContext != null) Navigator.of(dialogContext!, rootNavigator: true).pop();
        ScaffoldMessenger.of(rootContext).showSnackBar(
          const SnackBar(content: Text("No cards to export")),
        );
        return;
      }

      // Create APKG file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dbPath = path.join(tempDir.path, "col_$timestamp.anki2");

      final apkgPath = await _createApkgFile(
        cards: cards,
        deckName: deck.name,
        dbPath: dbPath,
        tempDir: tempDir,
        timestamp: timestamp,
      );

      // Get proper Downloads directory path
      String downloadsPath;
      if (Platform.isAndroid) {
        downloadsPath = '/storage/emulated/0/Download';
      } else if (Platform.isIOS) {
        final appDocDir = await getApplicationDocumentsDirectory();
        downloadsPath = appDocDir.path;
      } else {
        downloadsPath = tempDir.path;
      }

      // Ensure Downloads directory exists
      final downloadsDir = Directory(downloadsPath);
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = "${_sanitize(deck.name)}_$timestamp.apkg";
      final savedPath = path.join(downloadsPath, fileName);

      // Copy file to Downloads
      await File(apkgPath).copy(savedPath);

      // Cleanup temp files
      try {
        await File(dbPath).delete();
        await File(apkgPath).delete();
      } catch (_) {}

      // Close loading dialog
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }

      // Show success message
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text("✅ Saved to ${Platform.isAndroid ? 'Downloads' : 'Documents'}: $fileName"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text("Export failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    try {
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> _createApkgFile({
    required List cards,
    required String deckName,
    required String dbPath,
    required Directory tempDir,
    required int timestamp,
  }) async {
    final dbFile = File(dbPath);
    if (await dbFile.exists()) await dbFile.delete();

    // Open database
    final db = await openDatabase(dbPath, version: 1);

    // Set PRAGMA for optimization
    await db.rawQuery("PRAGMA synchronous = OFF");
    await db.rawQuery("PRAGMA journal_mode = DELETE");
    await db.rawQuery("PRAGMA temp_store = MEMORY");
    await db.rawQuery("PRAGMA locking_mode = EXCLUSIVE");
    await db.rawQuery("PRAGMA cache_size = -20000");
    await db.rawQuery("PRAGMA foreign_keys = OFF");

    final now = DateTime.now().millisecondsSinceEpoch;

    // Create schema - THÊM COLUMN imageUrl vào notes table
    await db.transaction((txn) async {
      await txn.execute(
          'CREATE TABLE notes (id INTEGER PRIMARY KEY, guid TEXT, mid INTEGER, mod INTEGER, usn INTEGER, tags TEXT, flds TEXT, sfld TEXT, csum INTEGER, flags INTEGER, data TEXT, imageUrl TEXT)'
      );
      await txn.execute(
          'CREATE TABLE cards (id INTEGER PRIMARY KEY, nid INTEGER, did INTEGER, ord INTEGER, mod INTEGER, usn INTEGER, type INTEGER, queue INTEGER, due INTEGER, ivl INTEGER, factor INTEGER, reps INTEGER, lapses INTEGER, left INTEGER, odue INTEGER, odid INTEGER, flags INTEGER, data TEXT)'
      );
      await txn.execute(
          'CREATE TABLE col (id INTEGER PRIMARY KEY, crt INTEGER, mod INTEGER, scm INTEGER, ver INTEGER, dty INTEGER, usn INTEGER, ls INTEGER, conf TEXT, models TEXT, decks TEXT, dconf TEXT, tags TEXT)'
      );

      await txn.insert("col", {
        "id": 1,
        "crt": now ~/ 1000,
        "mod": now,
        "scm": now,
        "ver": 11,
        "dty": 0,
        "usn": 0,
        "ls": 0,
        "conf": "{}",
        "models":
        '{"1":{"id":1,"name":"Basic","flds":[{"name":"Front"},{"name":"Back"}],"tmpls":[{"name":"Card 1","qfmt":"{{Front}}","afmt":"{{FrontSide}}<hr>{{Back}}"}]}}',
        "decks": '{"1":{"id":1,"name":"${_escapeJson(deckName)}"}}',
        "dconf": "{}",
        "tags": "{}"
      });
    });

    // Insert cards - LƯU imageUrl vào database
    await db.transaction((txn) async {
      final ts = now ~/ 1000;

      for (int i = 0; i < cards.length; i++) {
        final card = cards[i];
        final nid = i + 1;

        String flds = "${_escape(card.word)}\x1f${_escape(card.definition)}";
        if (card.example?.isNotEmpty ?? false) {
          flds += "\x1f${_escape(card.example!)}";
        }

        // LƯU imageUrl vào column imageUrl
        _log('Card ${i + 1}: word="${card.word}", imageUrl="${card.imageUrl ?? "null"}"');

        await txn.rawInsert(
            'INSERT INTO notes VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',
            [nid, card.id, 1, ts, -1, "", flds, card.word, card.word.hashCode.abs(), 0, "", card.imageUrl ?? ""]
        );

        await txn.rawInsert(
            'INSERT INTO cards VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
            [nid, nid, 1, 0, ts, -1, 0, 0, nid, 0, 2500, 0, 0, 0, 0, 0, 0, ""]
        );
      }
    });

    await db.close();
    _log('Database created with ${cards.length} cards');

    // Create ZIP/APKG
    final dbBytes = await File(dbPath).readAsBytes();
    final archive = Archive()
      ..addFile(ArchiveFile("collection.anki2", dbBytes.length, dbBytes));

    final zipBytes = ZipEncoder().encode(archive)!;
    final apkgPath = path.join(tempDir.path, "${_sanitize(deckName)}_$timestamp.apkg");
    await File(apkgPath).writeAsBytes(zipBytes);

    return apkgPath;
  }

  String _escapeJson(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n');

  String _escape(String s) => s
      .replaceAll('\x1f', '')
      .replaceAll('\n', '<br>')
      .trim();

  String _sanitize(String s) => s
      .replaceAll(RegExp(r'[^\w\s-]'), '_')
      .replaceAll(' ', '_');

  Future<void> _deleteDeck(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            Text('Are you sure you want to delete "${deck.name}"?'),
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
                      style: TextStyle(color: Colors.red, fontSize: 13),
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
        await _firebaseService.deleteDeck(deck.id);
        if (context.mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deck deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Deck Settings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfo(
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
                  _buildInfo(
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
                  _buildInfo(
                    Icons.check_circle,
                    '${deck.masteredWords}',
                    'Mastered',
                    Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildOption(
              Icons.upload_file,
              Colors.blue,
              Colors.blue.shade50,
              'Export to Anki',
              'Share as .apkg file',
                  () {
                Navigator.pop(context);
                _exportDeck(context);
              },
            ),
            const SizedBox(height: 12),
            _buildOption(
              Icons.download,
              Colors.green,
              Colors.green.shade50,
              'Export to Device',
              'Save .apkg to Downloads folder',
                  () {
                Navigator.pop(context);
                _exportToDevice(context);
              },
            ),
            const SizedBox(height: 12),
            _buildOption(
              Icons.delete_forever,
              Colors.red,
              Colors.red.shade50,
              'Delete Deck',
              'This action cannot be undone',
                  () => _deleteDeck(context),
              titleColor: Colors.red,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(IconData icon, String value, String label, Color color) {
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
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildOption(
      IconData icon,
      Color iconColor,
      Color bgColor,
      String title,
      String subtitle,
      VoidCallback onTap, {
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
                color: bgColor,
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
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}