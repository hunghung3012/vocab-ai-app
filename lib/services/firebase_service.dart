// lib/services/firebase_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/flashcard.dart';
import '../models/deck.dart';
import 'cloudinary_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  String? get userId => _auth.currentUser?.uid;

  // ===========================================================================
  // HELPER: Thống kê Deck (Logic mới quan trọng)
  // ===========================================================================

  /// Tính toán lại stats của Deck dựa trên các flashcard hiện có
  Future<void> updateDeckStats(String deckId) async {
    try {
      if (userId == null) throw Exception('User not logged in');

      // 1. Lấy tất cả cards thuộc deck này
      final cardsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .where('deckId', isEqualTo: deckId)
          .get();

      final totalWords = cardsSnapshot.docs.length;

      // 2. Đếm số từ đã "thuộc" (Mastered)
      // Điều kiện: easeFactor >= 2.5 và đã học ít nhất 4 lần
      final masteredWords = cardsSnapshot.docs.where((doc) {
        final data = doc.data();
        final easeFactor = data['easeFactor'] ?? 2.5;
        final repetitions = data['repetitions'] ?? 0;
        return easeFactor >= 2.5 && repetitions >= 4;
      }).length;

      // 3. Tính phần trăm
      final progress = totalWords > 0
          ? (masteredWords / totalWords * 100).toDouble()
          : 0.0;

      // 4. Cập nhật vào Deck document
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('decks')
          .doc(deckId)
          .update({
        'totalWords': totalWords,
        'masteredWords': masteredWords,
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Deck stats updated: $totalWords words, $masteredWords mastered');
    } catch (e) {
      print('Error updating deck stats: $e');
      // Không throw lỗi ở đây để tránh crash luồng chính nếu chỉ lỗi update stats
    }
  }

  // ===========================================================================
  // DECK OPERATIONS
  // ===========================================================================

  Future<void> createDeck(Deck deck) async {
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deck.id)
        .set(deck.toMap());
  }

  Future<void> updateDeck(Deck deck) async {
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deck.id)
        .update(deck.toMap());
  }

  Future<void> deleteDeck(String deckId) async {
    if (userId == null) throw Exception('User not authenticated');

    // Lấy danh sách card để xóa
    // Lưu ý: Ta dùng query trực tiếp thay vì getFlashcardsByDeck để tối ưu cho việc xóa
    final cardsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .where('deckId', isEqualTo: deckId)
        .get();

    final batch = _firestore.batch();

    // Thêm lệnh xóa từng card vào batch
    for (var doc in cardsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Thêm lệnh xóa deck vào batch
    final deckRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId);
    batch.delete(deckRef);

    // Thực thi batch (Atomic operation - an toàn hơn vòng lặp)
    await batch.commit();
  }

  Stream<List<Deck>> getDecksStream() {
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .orderBy('lastStudiedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Deck.fromMap(doc.data()))
        .toList());
  }

  Future<Deck?> getDeck(String deckId) async {
    if (userId == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId)
        .get();

    if (!doc.exists) return null;
    return Deck.fromMap(doc.data()!);
  }

  // ===========================================================================
  // FLASHCARD OPERATIONS (Updated logic)
  // ===========================================================================

  // 1. Tạo Flashcard -> Lưu deckId vào card -> Cập nhật Stats
  Future<void> createFlashcard(Flashcard card, String deckId) async {
    try {
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .doc(card.id)
          .set({
        ...card.toMap(),
        'deckId': deckId, // Quan trọng: Liên kết card với deck
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật stats cho deck
      await updateDeckStats(deckId);
    } catch (e) {
      print('Error creating flashcard: $e');
      rethrow;
    }
  }

  // 2. Cập nhật Flashcard -> Cập nhật Stats (vì có thể trạng thái mastered thay đổi)
  Future<void> updateFlashcard(Flashcard card) async {
    try {
      if (userId == null) throw Exception('User not authenticated');

      // Lấy deckId hiện tại của card (để biết cần update deck nào)
      final cardDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .doc(card.id)
          .get();

      final deckId = cardDoc.data()?['deckId'];

      // Cập nhật thông tin card
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .doc(card.id)
          .update({
        ...card.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật lại stats nếu tìm thấy deckId
      if (deckId != null) {
        await updateDeckStats(deckId);
      }
    } catch (e) {
      print('Error updating flashcard: $e');
      rethrow;
    }
  }

  // 3. Xóa Flashcard -> Cập nhật Stats
  Future<void> deleteFlashcard(String cardId) async {
    try {
      if (userId == null) throw Exception('User not authenticated');

      // Lấy thông tin card trước khi xóa để lấy deckId
      final cardDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .doc(cardId)
          .get();

      if (!cardDoc.exists) {
        // Card không tồn tại hoặc đã bị xóa
        return;
      }

      final deckId = cardDoc.data()?['deckId'];

      // Xóa card
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .doc(cardId)
          .delete();

      // Cập nhật lại stats
      if (deckId != null) {
        await updateDeckStats(deckId);
      }
    } catch (e) {
      print('Error deleting flashcard: $e');
      rethrow;
    }
  }

  // Lấy Flashcards bằng Query (Hiệu quả hơn dùng mảng IDs)
  Future<List<Flashcard>> getFlashcardsByDeck(String deckId) async {
    if (userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .where('deckId', isEqualTo: deckId)
          .get();

      return querySnapshot.docs
          .map((doc) => Flashcard.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting flashcards: $e');
      return [];
    }
  }

  // ===========================================================================
  // UPLOAD & STATISTICS
  // ===========================================================================

  Future<String> uploadImage(File imageFile, String deckId) async {
    try {
      final imageUrl = await _cloudinaryService.uploadImage(imageFile);
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    if (userId == null) return {};

    final decks = await getDecksStream().first;
    int totalWords = 0;
    int masteredWords = 0;

    for (var deck in decks) {
      totalWords += deck.totalWords;
      masteredWords += deck.masteredWords;
    }

    final streakDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('studyStreak')
        .get();

    int studyStreak = streakDoc.exists
        ? (streakDoc.data()?['days'] ?? 0)
        : 0;

    return {
      'totalWords': totalWords,
      'masteredWords': masteredWords,
      'studyStreak': studyStreak,
      'totalDecks': decks.length,
    };
  }

  Future<void> updateStudyStreak() async {
    if (userId == null) return;

    final streakRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('studyStreak');

    final doc = await streakRef.get();
    final now = DateTime.now();

    if (!doc.exists) {
      await streakRef.set({
        'days': 1,
        'lastStudyDate': now.toIso8601String(),
      });
      return;
    }

    final data = doc.data()!;
    final lastStudyStr = data['lastStudyDate'] as String?;

    if (lastStudyStr == null) return; // Guard clause

    final lastStudy = DateTime.parse(lastStudyStr);

    // Reset thời gian về đầu ngày để so sánh ngày chính xác
    final dateNow = DateTime(now.year, now.month, now.day);
    final dateLast = DateTime(lastStudy.year, lastStudy.month, lastStudy.day);

    final difference = dateNow.difference(dateLast).inDays;

    if (difference == 1) {
      // Học liên tiếp
      await streakRef.update({
        'days': (data['days'] ?? 0) + 1,
        'lastStudyDate': now.toIso8601String(),
      });
    } else if (difference > 1) {
      // Bị ngắt quãng
      await streakRef.update({
        'days': 1,
        'lastStudyDate': now.toIso8601String(),
      });
    } else {
      // Vẫn trong cùng 1 ngày -> chỉ cập nhật lastStudyDate
      await streakRef.update({
        'lastStudyDate': now.toIso8601String(),
      });
    }
  }
}